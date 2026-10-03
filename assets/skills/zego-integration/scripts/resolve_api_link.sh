#!/bin/bash
# resolve_api_link.sh — 解析 ZEGO API 短链（[text](@apiName)）到本地 API 参考 MDX 文件。
#
# 用法: resolve_api_link.sh <short_link> <current_mdx_path> [docs_root]
#   short_link:       API 名称，不含 @（如 startPublishingStream、sendSEI）
#   current_mdx_path: 短链所在 MDX 文件路径（相对 docs_root 或绝对路径）
#   docs_root:        文档仓库根目录（可省略，缺省依次取 $ZEGO_DOCS_ROOT、~/.cache/zego-integration/docs_all）
#
# 成功输出 4 行:
#   1. instance ID
#   2. 解析出的 URL 路径（如 /real-time-video-web/client-sdk/api-reference/class#startpublishingstream）
#   3. 本地 MDX 文件绝对路径
#   4. 锚点 slug（用于在文件内 grep 定位）
#
# 失败时 stderr 输出错误并 exit 1。

set -euo pipefail

if [ $# -lt 2 ]; then
  echo "用法: resolve_api_link.sh <short_link> <current_mdx_path> [docs_root]" >&2
  exit 1
fi

SHORT_LINK="$1"
CURRENT_MDX="$2"

# Resolve docs root: 显式参数 > 环境变量 > 默认缓存位置 > 从脚本位置向上查找
if [ $# -ge 3 ] && [ -f "$3/docuo.config.json" ]; then
  DOCS_ROOT="$3"
elif [ -n "${ZEGO_DOCS_ROOT:-}" ] && [ -f "$ZEGO_DOCS_ROOT/docuo.config.json" ]; then
  DOCS_ROOT="$ZEGO_DOCS_ROOT"
elif [ -f "$HOME/.cache/zego-integration/docs_all/docuo.config.json" ]; then
  DOCS_ROOT="$HOME/.cache/zego-integration/docs_all"
else
  DOCS_ROOT=""
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  dir="$SCRIPT_DIR"
  for _ in $(seq 1 10); do
    if [ -f "$dir/docuo.config.json" ]; then
      DOCS_ROOT="$dir"
      break
    fi
    dir="$(dirname "$dir")"
  done
fi

if [ -z "$DOCS_ROOT" ]; then
  echo "错误: 未找到文档仓库根目录（可用第 3 个参数或 ZEGO_DOCS_ROOT 指定）" >&2
  exit 1
fi

# 绝对路径归一化为相对 docs_root 的路径
case "$CURRENT_MDX" in
  /*) CURRENT_MDX="${CURRENT_MDX#"$DOCS_ROOT/"}" ;;
esac

CONFIG="$DOCS_ROOT/docuo.config.json"

# ---------- generateSlug: match the JS implementation ----------
# lowercase, remove non-word chars (except spaces and hyphens), spaces to hyphens
generate_slug() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 _-]//g' | sed 's/  */-/g' | sed 's/^-*//;s/-*$//'
}

# ---------- Find the instance for the current MDX file ----------
# Strategy: find the instance whose `path` is the longest prefix of CURRENT_MDX
BEST_INSTANCE_ID=""
BEST_INSTANCE_PATH=""
BEST_INSTANCE_ROUTE=""
BEST_INSTANCE_API=""
BEST_LEN=0

# Extract instances with clientApiPath using python (available everywhere)
INSTANCES=$(python3 -c "
import json, sys
with open('$CONFIG') as f:
    data = json.load(f)
for inst in data.get('instances', []):
    cap = inst.get('clientApiPath', '')
    if cap:
        print(inst.get('id',''), inst.get('path',''), inst.get('routeBasePath',''), cap)
" 2>/dev/null)

if [ -z "$INSTANCES" ]; then
  echo "Error: No instances with clientApiPath found in $CONFIG" >&2
  exit 1
fi

while IFS=' ' read -r inst_id inst_path inst_route inst_api; do
  # Check if current_mdx starts with instance path
  if [ "${CURRENT_MDX#"$inst_path"}" != "$CURRENT_MDX" ]; then
    len=${#inst_path}
    if [ "$len" -gt "$BEST_LEN" ]; then
      BEST_LEN=$len
      BEST_INSTANCE_ID=$inst_id
      BEST_INSTANCE_PATH=$inst_path
      BEST_INSTANCE_ROUTE=$inst_route
      BEST_INSTANCE_API=$inst_api
    fi
  fi
done <<< "$INSTANCES"

if [ -z "$BEST_INSTANCE_ID" ]; then
  echo "Error: No matching instance for $CURRENT_MDX" >&2
  exit 1
fi

API_DIR="$DOCS_ROOT/$BEST_INSTANCE_PATH/$BEST_INSTANCE_API"

if [ ! -d "$API_DIR" ]; then
  echo "Error: API directory not found: $API_DIR" >&2
  exit 1
fi

# ---------- Parse the short link ----------
# Heading link: starts with - (e.g., @-ZegoEngine)
# Method link: everything else
PARENT_TYPES="class interface enum protocol struct"

if [ "${SHORT_LINK:0:1}" = "-" ]; then
  LINK_TYPE="heading"
  RAW="${SHORT_LINK:1}"
else
  LINK_TYPE="method"
  RAW="$SHORT_LINK"
fi

# For heading links, check for type suffix (e.g., ZegoEngine-class)
SPECIFIED_TYPE=""
if [ "$LINK_TYPE" = "heading" ]; then
  for ptype in $PARENT_TYPES; do
    suffix="-${ptype}"
    if [ "${RAW,,}" = "${RAW%$suffix}${suffix}" ] && [ "${RAW,,}" != "${RAW%$suffix}" ]; then
      SPECIFIED_TYPE="$ptype"
      RAW="${RAW%$suffix}"
      break
    fi
  done
fi

# Generate anchor slug from the raw name
# Handle overload suffix: __1 → strip (simplified from full logic)
RAW_CLEAN="${RAW//__}"
ANCHOR=$(generate_slug "$RAW_CLEAN")

# ---------- Build URL base ----------
URL_BASE="/${BEST_INSTANCE_ROUTE}/${BEST_INSTANCE_API}"
URL_BASE=$(echo "$URL_BASE" | sed 's#/\+#/#g')

# ---------- Search for the anchor in API MDX files ----------
found_file=""
found_type=""

search_in_file() {
  local file="$1"
  local ftype="$2"
  if [ ! -f "$file" ]; then return 1; fi

  # For method links: search ParamField name= attributes
  # Normalize file content (collapse newlines) and match name="..."
  # Use grep to find lines containing name= with our anchor text
  local anchor_pattern
  anchor_pattern=$(echo "$ANCHOR" | sed 's/-/ /g')

  # Search for ParamField with name matching (case-insensitive slug match)
  # The name attr preserves original case, so search case-insensitively
  if grep -qi "name=\"${RAW_CLEAN}\"" "$file" 2>/dev/null; then
    return 0
  fi
  # Also try the original short link directly
  if grep -qi "name=\"${SHORT_LINK}\"" "$file" 2>/dev/null; then
    return 0
  fi
  # Try with overload normalization
  if [ "${RAW}" != "${RAW_CLEAN}" ] && grep -qi "name=\"${RAW_CLEAN}\"" "$file" 2>/dev/null; then
    return 0
  fi

  return 1
}

if [ "$LINK_TYPE" = "heading" ]; then
  # For heading links, search ## headings
  search_heading() {
    local file="$1"
    local ftype="$2"
    if [ ! -f "$file" ]; then return 1; fi
    # Search for headings matching the slug
    local heading_text
    heading_text=$(echo "$ANCHOR" | sed 's/-/ /g')
    if grep -qi "^##\+ .*$heading_text" "$file" 2>/dev/null; then
      return 0
    fi
    return 1
  }

  if [ -n "$SPECIFIED_TYPE" ]; then
    file="$API_DIR/${SPECIFIED_TYPE}.mdx"
    if search_heading "$file" "$SPECIFIED_TYPE"; then
      found_file="$file"
      found_type="$SPECIFIED_TYPE"
    fi
  fi

  if [ -z "$found_file" ]; then
    for ptype in $PARENT_TYPES; do
      file="$API_DIR/${ptype}.mdx"
      if search_heading "$file" "$ptype"; then
        found_file="$file"
        found_type="$ptype"
        break
      fi
    done
  fi
else
  # Method links: search ParamField in order
  if [ -n "$SPECIFIED_TYPE" ]; then
    file="$API_DIR/${SPECIFIED_TYPE}.mdx"
    if search_in_file "$file" "$SPECIFIED_TYPE"; then
      found_file="$file"
      found_type="$SPECIFIED_TYPE"
    fi
  fi

  if [ -z "$found_file" ]; then
    for ptype in $PARENT_TYPES; do
      file="$API_DIR/${ptype}.mdx"
      if search_in_file "$file" "$ptype"; then
        found_file="$file"
        found_type="$ptype"
        break
      fi
    done
  fi
fi

if [ -z "$found_file" ]; then
  echo "Error: Cannot resolve @${SHORT_LINK} in any API file under $API_DIR" >&2
  echo "  Searched anchor: ${ANCHOR}" >&2
  exit 1
fi

# ---------- Output ----------
FULL_URL="${URL_BASE}/${found_type}#${ANCHOR}"
ABS_PATH=$(cd "$(dirname "$found_file")" && pwd)/$(basename "$found_file")

echo "$BEST_INSTANCE_ID"
echo "$FULL_URL"
echo "$ABS_PATH"
echo "$ANCHOR"
