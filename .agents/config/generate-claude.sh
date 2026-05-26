#!/usr/bin/env bash
# 生成 .claude/settings.json（项目级，提交到仓库）
# 数据源: lib/claude-config.nix → nix eval → settings.json
# 与 generate-opencode.sh 对应
set -euo pipefail

ROOT=$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel)
cd "$ROOT"

echo "Reading config from Nix..."
nix eval .#claudeConfig.settings --json | python3 -c "
import sys, json
with open('.claude/settings.json', 'w') as f:
    json.dump(json.load(sys.stdin), f, indent=2)
    f.write('\n')
"
echo "  generated .claude/settings.json"
echo "Done."
