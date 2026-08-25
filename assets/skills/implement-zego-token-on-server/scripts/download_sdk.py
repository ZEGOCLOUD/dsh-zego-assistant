#!/usr/bin/env python3
"""
下载 ZEGO Server Assistant SDK

用法:
    python download_sdk.py --language <LANGUAGE_ID>
    python download_sdk.py --list

支持的语言:
    GO, CPP, JAVA, PYTHON, NODEJS, PHP, CSHARP
"""

import argparse
import os
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

# 各语言的常见 SDK 目录（按优先级排序）
LANGUAGE_SDK_DIRS = {
    "GO": [
        "pkg/zego/token",
        "internal/zego/token",
        "zego/token",
        "utils/zego/token",
        "lib/zego/token",
        "sdk/zego/token",
    ],
    "PYTHON": [
        "zego/token",
        "utils/zego/token",
        "lib/zego/token",
        "services/zego/token",
        "sdk/zego/token",
    ],
    "NODEJS": [
        "zego/token",
        "utils/zego/token",
        "lib/zego/token",
        "services/zego/token",
        "src/zego/token",
        "sdk/zego/token",
    ],
    "JAVA": [
        "src/main/java/im/zego/serverassistant/utils",
        "im/zego/serverassistant/utils",
        "zego/token",
        "utils/zego/token",
        "lib/zego/token",
        "sdk/zego/token",
    ],
    "PHP": [
        "ZEGO/Token",
        "zego/token",
        "utils/zego/token",
        "lib/zego/token",
        "sdk/zego/token",
    ],
    "CSHARP": [
        "ZegoServerAssistant",
        "Services/ZegoServerAssistant",
        "Utils/ZegoServerAssistant",
        "zego/token",
        "sdk/ZegoServerAssistant",
    ],
    "CPP": [
        "zego/token",
        "utils/zego/token",
        "lib/zego/token",
        "src/zego/token",
        "sdk/zego/token",
    ],
}

# 各语言的框架标识文件
FRAMEWORK_MARKERS = {
    "NODEJS": ["package.json"],
    "PYTHON": ["requirements.txt", "setup.py", "pyproject.toml"],
    "GO": ["go.mod", "go.sum"],
    "JAVA": ["pom.xml", "build.gradle", "build.gradle.kts"],
    "PHP": ["composer.json"],
    "CSHARP": [".csproj", "sln"],
    "CPP": ["CMakeLists.txt", "Makefile", "vcpkg.json"],
}


def get_workspace_root() -> Path:
    """获取 workspace 根目录"""
    # 从环境变量获取
    workspace_path = os.environ.get("CLAUDE_CODE_WORKSPACE")
    if workspace_path:
        return Path(workspace_path)

    # 从当前脚本位置向上查找
    script_dir = Path(__file__).parent.resolve()
    # 脚本位于 skills/server-token-integration/scripts/
    # 需要向上查找 workspace 根目录
    current = script_dir
    for _ in range(6):  # 向上最多6级
        current = current.parent
        if (current / ".git").exists() or (current / "package.json").exists() or (current / "go.mod").exists():
            return current

    # 默认返回当前工作目录
    return Path.cwd()


def detect_project_language(workspace_root: Path) -> str | None:
    """检测项目使用的语言"""
    for lang, markers in FRAMEWORK_MARKERS.items():
        for marker in markers:
            # 检查根目录
            if (workspace_root / marker).exists():
                return lang
            # 检查 src 目录
            if (workspace_root / "src" / marker).exists():
                return lang
    return None


def find_common_sdk_dirs(workspace_root: Path) -> list[str]:
    """查找项目中常见的 SDK 目录"""
    common_dirs = []
    candidates = [
        "lib", "libs", "utils", "common", "shared",
        "sdk", "sdk", "services", "helpers"
    ]

    for candidate in candidates:
        dir_path = workspace_root / candidate
        if dir_path.exists() and dir_path.is_dir():
            common_dirs.append(candidate)

    return common_dirs


def determine_output_dir(workspace_root: Path, lang: str) -> tuple[Path, str]:
    """
    确定输出目录

    Returns:
        (输出路径, 使用的目录模式)
    """
    # 首先尝试在项目中找到已存在的 zego 相关目录
    existing_zego_dirs = []
    max_depth = 3
    for root, dirs, _ in os.walk(workspace_root):
        # 计算当前深度
        current_depth = len(Path(root).relative_to(workspace_root).parts)
        if current_depth > max_depth:
            # 只检查子目录，不继续深入
            dirs.clear()
            continue
        if 'zego' in dirs:
            existing_zego_dirs.append(Path(root) / 'zego')

    # 如果找到 zego 目录，优先使用
    if existing_zego_dirs:
        # 选择最接近根目录的
        selected = existing_zego_dirs[0]
        return selected / 'token', 'existing_zego_dir'

    # 获取该语言推荐的目录列表
    lang_dirs = LANGUAGE_SDK_DIRS.get(lang, ["zego/token"])

    # 检查项目中存在的通用目录
    common_dirs = find_common_sdk_dirs(workspace_root)

    # 遍历语言推荐目录，找到第一个部分匹配的
    for recommended in lang_dirs:
        # 检查推荐目录是否已存在
        full_path = workspace_root / recommended
        if full_path.exists():
            return full_path, 'existing_recommended_dir'

        # 检查推荐目录的父目录是否存在于项目中
        parent_name = recommended.split('/')[0] if '/' in recommended else recommended
        if parent_name in common_dirs:
            return full_path, 'project_common_dir'

    # 如果是单体仓库，尝试在 src 或特定项目目录下创建
    src_dir = workspace_root / "src"
    if src_dir.exists() and src_dir.is_dir():
        return src_dir / "zego" / "token", 'src_dir'

    # 默认：使用 workspace 根目录下的 zego/token
    return workspace_root / "zego" / "token", 'default'


def download_file(url: str, target_path: Path) -> bool:
    """下载文件到目标路径"""
    try:
        print(f"正在下载: {url}")
        with urlopen(url, timeout=30) as response:
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
        print(f"下载失败: {str(e)}", file=sys.stderr)
        return False


def main():
    parser = argparse.ArgumentParser(description="下载 ZEGO Server Assistant SDK")
    parser.add_argument("--language", "-l", help="SDK 语言 (GO, CPP, JAVA, PYTHON, NODEJS, PHP, CSHARP)")
    parser.add_argument("--output", "-o", help="输出文件路径（可选）")
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

    # 获取 workspace 根目录
    workspace_root = get_workspace_root()
    print(f"工作目录: {workspace_root}")

    # 确定输出路径
    if args.output:
        output_path = Path(args.output)
    else:
        # 智能确定输出目录
        output_dir, dir_mode = determine_output_dir(workspace_root, lang)
        output_path = output_dir / FILE_NAMES[lang]
        print(f"目录模式: {dir_mode}")

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
