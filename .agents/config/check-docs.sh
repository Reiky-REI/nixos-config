#!/usr/bin/env bash
# check-docs.sh — 检查 README 里引用的仓库路径是否仍然存在
# 目的: 重命名/迁移/删除文件后, 文档容易漂移; 这里做廉价的事实校验.
# 范围: README.md 反引号内的仓库内相对路径 (hosts/ modules/ home/ lib/ pkgs/ secrets/ .agents/ docs/)
# 跳过: 含 { * < > $ 的模板/示例 token
# 用法: check-docs.sh [--verbose]
set -euo pipefail

ROOT="$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel)"
cd "$ROOT"

python3 - "$@" <<'PY'
import os
import re
import sys

verbose = "--verbose" in sys.argv
text = open("README.md", encoding="utf-8").read()
tokens = re.findall(r"`([^`\n]+)`", text)
prefixes = ("hosts/", "modules/", "home/", "lib/", "pkgs/", "secrets/", ".agents/", "docs/")

checked = 0
missing = []
for token in tokens:
    # 跳过模板/通配/变量示例
    if any(ch in token for ch in "{*<>$"):
        continue
    if not token.startswith(prefixes):
        continue
    path = token.split("#")[0].rstrip(".,;:")
    checked += 1
    if not os.path.exists(path):
        missing.append(token)

if verbose:
    print(f"check-docs: 已检查 {checked} 个 README 仓库路径")

if missing:
    print("check-docs: README 引用了不存在的路径:", file=sys.stderr)
    for item in missing:
        print(f"  - {item}", file=sys.stderr)
    sys.exit(1)

print(f"OK check-docs: {checked} 个 README 仓库路径全部存在")
PY
