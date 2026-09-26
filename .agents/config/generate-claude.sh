#!/usr/bin/env bash
# 生成 .claude/settings.json（项目级，提交到仓库）
# 数据源: lib/claude-config.nix → nix eval → settings.json
# 与 generate-opencode.sh 对应
set -euo pipefail

ROOT=$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel)
cd "$ROOT"

echo "Reading config from Nix..."
nix eval .#claudeConfig.settings --json --accept-flake-config > .claude/settings.json
echo "  generated .claude/settings.json"
echo "Done."
