#!/bin/bash
# update_docs.sh — 下载/更新 ZEGO 文档仓库快照（tarball 方式，不含 git 历史）
#
# 用法:
#   bash update_docs.sh [--force]
#     --force  忽略 TTL 节流，强制检查远端更新
#
# 环境变量:
#   ZEGO_DOCS_ROOT  文档仓库缓存位置（默认 ~/.cache/zego-integration/docs_all）
#   ZEGO_DOCS_TTL   远端检查节流秒数（默认 600，即 10 分钟内不重复检查）
#
# 输出（stdout 末尾的 KEY=VALUE 行供 agent 解析）:
#   DOCS_ROOT=<路径>
#   REVISION=<commit sha 或 unknown>
#   STATUS=ready|updated|cached|offline
#     ready    首次下载完成
#     updated  检测到更新并已替换
#     cached   TTL 内或远端无变化，直接使用本地
#     offline  网络不可用，降级使用本地现有版本（exit 0）
#
# 失败（本地无文档且无法下载）时 exit 1。

set -euo pipefail

REPO="ZEGOCLOUD/docs_all"
BRANCH="main"
TTL="${ZEGO_DOCS_TTL:-600}"

# ---------------- 参数 ----------------
FORCE=0
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    *) echo "未知参数: $arg" >&2; exit 1 ;;
  esac
done

# ---------------- 路径 ----------------
CACHE_BASE="${ZEGO_DOCS_ROOT:-$HOME/.cache/zego-integration}"
if [ -d "$CACHE_BASE" ] && [ -f "$CACHE_BASE/docuo.config.json" ]; then
  # 用户把 ZEGO_DOCS_ROOT 直接指向了仓库本身
  DOCS_ROOT="$CACHE_BASE"
  CACHE_BASE="$(dirname "$CACHE_BASE")"
else
  DOCS_ROOT="$CACHE_BASE/docs_all"
fi
STATE_FILE="$CACHE_BASE/docs_all.state"
LOCK_DIR="$CACHE_BASE/.update-lock"
mkdir -p "$CACHE_BASE"

now=$(date +%s)
mtime_of() {  # macOS/Linux 兼容的 mtime
  stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo "$now"
}
read_state() {  # 输出: <sha> <last_check_ts>
  if [ -f "$STATE_FILE" ]; then
    head -2 "$STATE_FILE" | tr '\n' ' ' | awk '{print $1, $2}'
  else
    echo "unknown 0"
  fi
}
write_state() {  # write_state <sha>
  printf '%s\n%s\n' "$1" "$now" > "$STATE_FILE"
}

cleanup() { rm -rf "$LOCK_DIR" "${TMP_DIR:-}"; }
trap cleanup EXIT

# ---------------- 下载通道 ----------------
# 直连 api.github.com 优先，失败依次回退 gh-proxy.com / gh-proxy.net 镜像（国内外网络均可工作）
fetch() {  # fetch <url> <output_file>；成功返回 0
  local url="$1" out="$2"
  if curl -fsSL --connect-timeout 10 --max-time 300 -o "$out" "$url" 2>/dev/null; then return 0; fi
  curl -fsSL --connect-timeout 10 --max-time 300 -o "$out" "https://gh-proxy.com/$url" 2>/dev/null && return 0
  curl -fsSL --connect-timeout 10 --max-time 300 -o "$out" "https://gh-proxy.net/$url" 2>/dev/null
}

get_remote_sha() {  # 输出 40 位 sha，失败输出空
  local tmp; tmp=$(mktemp)
  if fetch "https://api.github.com/repos/$REPO/commits/$BRANCH" "$tmp"; then
    grep -o '"sha": *"[0-9a-f]\{40\}"' "$tmp" | head -1 | cut -d'"' -f4
  fi
  rm -f "$tmp"
}

download_snapshot() {  # download_snapshot <tmp_tarball>
  fetch "https://api.github.com/repos/$REPO/tarball/$BRANCH" "$1" || \
  fetch "https://github.com/$REPO/archive/refs/heads/$BRANCH.tar.gz" "$1"
}

install_snapshot() {  # install_snapshot <tmp_tarball> <new_sha>
  local tarball="$1" sha="$2"
  TMP_DIR=$(mktemp -d "$CACHE_BASE/.tmp.XXXXXX")
  mkdir "$TMP_DIR/src"
  tar -xzf "$tarball" -C "$TMP_DIR/src" --strip-components=1
  [ -f "$TMP_DIR/src/docuo.config.json" ] || { echo "错误: 快照内容异常（缺少 docuo.config.json）" >&2; return 1; }
  local old="$DOCS_ROOT.old"
  rm -rf "$old"
  if [ -d "$DOCS_ROOT" ]; then mv "$DOCS_ROOT" "$old"; fi
  mv "$TMP_DIR/src" "$DOCS_ROOT"
  rm -rf "$old" "$TMP_DIR"; TMP_DIR=""
  write_state "$sha"
}

emit() {  # emit <status> <revision>
  echo "DOCS_ROOT=$DOCS_ROOT"
  echo "REVISION=${2:-unknown}"
  echo "STATUS=$1"
}

# ---------------- 主流程 ----------------
# 单实例锁（10 分钟以上的残留锁视为失效）
if mkdir "$LOCK_DIR" 2>/dev/null; then
  :
else
  lock_age=$(( now - $(mtime_of "$LOCK_DIR") ))
  if [ "$lock_age" -gt 600 ]; then rm -rf "$LOCK_DIR" && mkdir "$LOCK_DIR"; else
    echo "另一个更新进程正在运行，直接使用本地文档。" >&2
    emit offline "$(read_state | awk '{print $1}')"
    exit 0
  fi
fi

set -- $(read_state)
LOCAL_SHA="${1:-unknown}"; LAST_CHECK="${2:-0}"

if [ ! -d "$DOCS_ROOT" ]; then
  echo "本地无文档仓库，开始下载快照（压缩包约 30~40MB）..." >&2
  remote_sha=$(get_remote_sha)
  tarball=$(mktemp -t zego_docs).tar.gz
  if download_snapshot "$tarball"; then
    install_snapshot "$tarball" "${remote_sha:-unknown}" && rm -f "$tarball"
    echo "下载完成。" >&2
    emit ready "${remote_sha:-unknown}"
  else
    rm -f "$tarball"
    echo "错误: 无法下载文档仓库（直连与镜像均失败），且本地没有可用副本。" >&2
    exit 1
  fi
  exit 0
fi

# TTL 节流：同一会话内反复调用只检查一次远端
if [ "$FORCE" -eq 0 ] && [ $(( now - LAST_CHECK )) -lt "$TTL" ] && [ "$LOCAL_SHA" != "unknown" ]; then
  emit cached "$LOCAL_SHA"
  exit 0
fi

echo "检查远端更新..." >&2
REMOTE_SHA=$(get_remote_sha)
write_state "${REMOTE_SHA:-unknown}"

if [ -z "$REMOTE_SHA" ]; then
  echo "警告: 无法查询远端版本，降级使用本地副本（$DOCS_ROOT）。" >&2
  emit offline "$LOCAL_SHA"
  exit 0
fi

if [ "$REMOTE_SHA" = "$LOCAL_SHA" ]; then
  emit cached "$REMOTE_SHA"
  exit 0
fi

echo "检测到文档更新（$LOCAL_SHA -> $REMOTE_SHA），下载新快照..." >&2
tarball=$(mktemp -t zego_docs).tar.gz
if download_snapshot "$tarball"; then
  install_snapshot "$tarball" "$REMOTE_SHA" && rm -f "$tarball"
  echo "更新完成。" >&2
  emit updated "$REMOTE_SHA"
else
  rm -f "$tarball"
  echo "警告: 检测到更新但下载失败，继续使用本地副本。" >&2
  emit offline "$LOCAL_SHA"
fi
