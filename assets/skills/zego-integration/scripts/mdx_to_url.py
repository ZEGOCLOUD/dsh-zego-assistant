#!/usr/bin/env python3
"""本地 mdx 文件 -> 公网文档 URL。

用法: python3 mdx_to_url.py <docs_root> <mdx_path>
  docs_root: 文档仓库根目录（含 docuo.config.*.json）
  mdx_path:  仓库内任意 mdx 文件（绝对路径或相对 docs_root 的路径）

输出: 每个命中的语言版本一行 "<locale>\t<url>"（zh -> doc-zh.zego.im，en -> www.zegocloud.com/docs）。
      未命中任何 instance 时 exit 1（常见原因：该文件是 snippets 等共享片段，本身没有公网页面）。
"""

import sys
import json
import re
from pathlib import Path

from find_mdx import path_to_file_id

LOCALES = [
    ("zh", "docuo.config.zh.json", "https://doc-zh.zego.im", ""),
    ("en", "docuo.config.en.json", "https://www.zegocloud.com", "/docs"),
]


def load_instances(docs_root: Path, config_name: str):
    cfg_file = docs_root / config_name
    if not cfg_file.exists():
        return []
    try:
        return json.loads(cfg_file.read_text("utf-8")).get("instances", [])
    except Exception:
        return []


def find_instance(docs_root: Path, rel_path: str, instances):
    """返回 (instance, 去掉 instance 前缀后的相对路径)，最长前缀匹配。"""
    best = None
    for inst in instances:
        inst_path = (inst.get("path") or "").strip("/")
        if not inst_path:
            continue
        prefix = inst_path + "/"
        if rel_path == inst_path or rel_path.startswith(prefix):
            if best is None or len(inst_path) > len(best[0].get("path", "")):
                best = (inst, rel_path[len(prefix):])
    return best


def main():
    if len(sys.argv) < 3:
        print(__doc__, file=sys.stderr)
        sys.exit(1)

    docs_root = Path(sys.argv[1]).resolve()
    mdx = Path(sys.argv[2]).resolve()
    try:
        rel = mdx.relative_to(docs_root).as_posix()
    except ValueError:
        print(f"错误: {mdx} 不在 {docs_root} 之内", file=sys.stderr)
        sys.exit(1)

    hits = []
    for locale, config_name, base, prefix in LOCALES:
        result = find_instance(docs_root, rel, load_instances(docs_root, config_name))
        if not result:
            continue
        inst, remaining = result
        file_id = path_to_file_id(remaining)
        route = (inst.get("routeBasePath") or "").strip("/")
        url = f"{base}{prefix}/{route}/{file_id}" if route else f"{base}{prefix}/{file_id}"
        hits.append((locale, url))

    if not hits:
        print(f"错误: {rel} 不属于任何 instance（可能是 snippets/ 共享片段，无独立公网页面）", file=sys.stderr)
        sys.exit(1)

    for locale, url in hits:
        print(f"{locale}\t{url}")


if __name__ == "__main__":
    main()
