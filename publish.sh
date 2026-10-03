#!/bin/bash
# publish.sh — 检查上游 zego-integration skill 更新，同步并发布 dsh-zego-assistant 到 npm。
#
# 用法（在 main 分支、干净工作区下运行）:
#   ./publish.sh              # 上游有更新时：同步 → 版本 patch +1 → npm publish → 推送
#   ./publish.sh minor        # 指定版本级别 patch|minor|major（默认 patch）
#
# 行为:
#   1. 浅克隆上游 ZEGOCLOUD/zego-integration（直连失败自动回退 ghfast.top / gh-proxy.com 镜像）
#   2. rsync 同步到 assets/skills/zego-integration/（排除上游仓库级文件）
#   3. 无变化：不做任何事；有变化：提交同步 → npm version → npm publish（2FA 在终端输 OTP）
#      → git push。若本地版本号已领先 registry（上次发布中断），沿用现有版本号只发布。
#
# 仅在本地终端运行——npm publish 的 2FA OTP 需要交互输入。

set -euo pipefail

REPO_URL="https://github.com/ZEGOCLOUD/zego-integration.git"
SKILL_DIR="assets/skills/zego-integration"
LEVEL="${1:-patch}"
REGISTRY="https://registry.npmjs.org"

case "$LEVEL" in
  patch|minor|major) ;;
  *) echo "用法: ./publish.sh [patch|minor|major]" >&2; exit 1 ;;
esac

# --- 前置检查 ---
BRANCH=$(git branch --show-current)
[ "$BRANCH" = "main" ] || { echo "错误: 请在 main 分支运行（当前: ${BRANCH}）" >&2; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "错误: 工作区有未提交改动，先处理再运行" >&2; exit 1; }
npm whoami --registry "$REGISTRY" >/dev/null 2>&1 || { echo "错误: 未登录 npm，先运行 npm login" >&2; exit 1; }

# --- 拉取上游（直连 → 镜像回退） ---
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
echo "检查上游 $REPO_URL ..."
UPSTREAM_SHA=""
for prefix in "" "https://ghfast.top/" "https://gh-proxy.com/"; do
  if git clone -q --depth 1 "${prefix}${REPO_URL}" "$TMP/upstream" 2>/dev/null; then
    UPSTREAM_SHA=$(git -C "$TMP/upstream" rev-parse --short HEAD)
    break
  fi
done
[ -n "$UPSTREAM_SHA" ] || { echo "错误: 无法克隆上游仓库（直连与镜像均失败），请检查网络。" >&2; exit 1; }

# --- 同步 skill 内容 ---
mkdir -p "$SKILL_DIR"
rsync -a --delete \
  --exclude='.git' --exclude='.gitignore' --exclude='.github' \
  --exclude='README.md' --exclude='LICENSE' --exclude='install.sh' \
  --exclude='.tmp' \
  "$TMP/upstream/" "$SKILL_DIR/"

if [ -z "$(git status --porcelain -- "$SKILL_DIR")" ]; then
  echo "上游无变化（@${UPSTREAM_SHA}），无需发布。"
  exit 0
fi

echo "检测到上游更新（@${UPSTREAM_SHA}），同步并发布..."
git add "$SKILL_DIR"
git commit -q -m "chore(sync): zego-integration skill @ ${UPSTREAM_SHA}"

# --- 版本号：本地已领先 registry（上次发布中断）则沿用，否则按级别递增 ---
LOCAL_VER=$(node -p "require('./package.json').version")
REMOTE_VER=$(npm view dsh-zego-assistant version --registry "$REGISTRY" 2>/dev/null || echo "0.0.0")
if [ "$LOCAL_VER" = "$REMOTE_VER" ]; then
  npm version "$LEVEL" >/dev/null
  echo "版本: $LOCAL_VER -> $(node -p "require('./package.json').version")"
else
  echo "本地版本 $LOCAL_VER 尚未发布（registry 为 ${REMOTE_VER}），沿用现有版本号发布。"
fi

# --- 发布（2FA 账号在终端输入 OTP） ---
npm publish --registry "$REGISTRY" --access public

# --- 推送（同步提交 + 版本提交 + tag） ---
git push
git push --tags
echo "完成: v$(node -p "require('./package.json').version") 已发布到 npm，git 已推送。"
