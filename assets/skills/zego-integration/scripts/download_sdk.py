#!/usr/bin/env python3
"""
下载 ZEGO Server Assistant SDK

用法:
    python download_sdk.py --language <LANGUAGE_ID>
    python download_sdk.py --language <LANGUAGE_ID> --output <文件路径>
    python download_sdk.py --list

支持的语言:
    GO, CPP, JAVA, PYTHON, NODEJS, PHP, CSHARP
"""

from __future__ import annotations  # 兼容 Python 3.9 的 X | Y 类型注解写法

import argparse
import sys
from pathlib import Path
from urllib.request import urlopen

# SDK 下载地址映射
SDK_URLS = {
    "GO": "https://raw.githubusercontent.com/zegoim/zego_server_assistant/refs/heads/release/github/token/go/src/token04/token04.go",
    "CPP": "https://raw.githubusercontent.com/zegoim/zego_server_assistant/refs/heads/release/github/token/c%2B%2B/token04/kernel/impl/ZegoServerAssistantImpl.cpp",
    "JAVA": "https://raw.githubusercontent.com/zegoim/zego_server_assistant/refs/heads/release/github/token/java/token04/src/im/zego/serverassistant/utils/TokenServerAssistant.java",
    "PYTHON": "https://raw.githubusercontent.com/zegoim/zego_server_assistant/refs/heads/release/github/token/python/token04/src/token04.py",
    "NODEJS": "https://raw.githubusercontent.com/zegoim/zego_server_assistant/refs/heads/release/github/token/nodejs/token04/server/zegoServerAssistant.ts",
    "PHP": "https://raw.githubusercontent.com/zegoim/zego_server_assistant/refs/heads/release/github/token/php/token04/src/ZEGO/ZegoServerAssistant.php",
    "CSHARP": "https://raw.githubusercontent.com/zegoim/zego_server_assistant/refs/heads/release/github/token/.net/token04/src/ZegoServerAssistant/GenerateToken.cs",
}

# 推荐的保存文件名
FILE_NAMES = {
    "GO": "token04.go",
    "CPP": "ZegoServerAssistantImpl.cpp",
    "JAVA": "TokenServerAssistant.java",
    "PYTHON": "token04.py",
    "NODEJS": "zegoServerAssistant.ts",
    "PHP": "ZegoServerAssistant.php",
    "CSHARP": "GenerateToken.cs",
}


def download_file(url: str, target_path: Path) -> bool:
    """下载文件到目标路径（直连失败时自动回退 gh-proxy.com / gh-proxy.net 镜像）"""
    candidates = [url]
    if "github.com" in url or "githubusercontent.com" in url:
        candidates.append("https://gh-proxy.com/" + url)
        candidates.append("https://gh-proxy.net/" + url)

    last_err = None
    for u in candidates:
        try:
            print(f"正在下载: {u}")
            with urlopen(u, timeout=30) as response:
                content = response.read()

            # 确保目标目录存在
            target_path.parent.mkdir(parents=True, exist_ok=True)

            # 写入文件
            with open(target_path, 'wb') as f:
                f.write(content)

            print(f"下载成功: {target_path}")
            print(f"文件大小: {len(content)} 字节")
            return True
        except Exception as e:
            last_err = e
            print(f"该通道下载失败: {str(e)}", file=sys.stderr)

    print(f"下载失败: {str(last_err)}", file=sys.stderr)
    return False


def main():
    parser = argparse.ArgumentParser(description="下载 ZEGO Server Assistant SDK")
    parser.add_argument("--language", "-l", help="SDK 语言 (GO, CPP, JAVA, PYTHON, NODEJS, PHP, CSHARP)")
    parser.add_argument("--output", "-o", help="输出文件路径（缺省为当前目录下该语言的源文件名）")
    parser.add_argument("--list", action="store_true", help="列出所有支持的语言")

    args = parser.parse_args()

    # 列出支持的语言
    if args.list:
        print("支持的语言:")
        for lang, url in SDK_URLS.items():
            print(f"  {lang:10} - {FILE_NAMES[lang]}")
        return 0

    # 检查语言参数
    if not args.language:
        parser.print_help()
        print("\n错误: 请指定 --language 参数")
        return 1

    lang = args.language.upper()

    # 验证语言是否支持
    if lang not in SDK_URLS:
        print(f"错误: 不支持的语言 '{lang}'", file=sys.stderr)
        print(f"支持的语言: {', '.join(SDK_URLS.keys())}", file=sys.stderr)
        return 1

    # 确定输出路径（默认下载到当前目录；各语言在项目中的建议存放位置见 references/token/sdk-urls.md）
    if args.output:
        output_path = Path(args.output)
    else:
        output_path = Path.cwd() / FILE_NAMES[lang]

    # 获取 URL 和下载
    url = SDK_URLS[lang]
    success = download_file(url, output_path)

    if not success:
        return 1

    # 输出 JSON 格式供脚本调用
    print(f"\n{{\"path\": \"{output_path}\", \"language\": \"{lang}\", \"filename\": \"{FILE_NAMES[lang]}\"}}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
