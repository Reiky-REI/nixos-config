#!/usr/bin/env bash
# rotate-nix-token.sh — 轮换 NIX_ACCESS_TOKEN (GitHub token)
#
# 为什么需要它:
#   - 构建时 env.sh 优先 source agenix 密钥 `secrets/ai_api_key_REIKY_REI.age`,
#     其中的 `export NIX_ACCESS_TOKEN=...` 才是真正生效的那个;
#     `.agents/config/token` 只是 agenix 不可用时的回退。
#   - 所以轮换必须改 **agenix 密钥**, 光改回退文件没用 (会被 agenix 盖掉)。
#
# 用法 (在 zsh/bash 里都行, 用 bash 跑):
#   bash .agents/config/rotate-nix-token.sh
#
# 它会: 提示你粘贴新 token (不回显) → 备份旧密钥 → 只替换 NIX_ACCESS_TOKEN 一行
#       (其余 API key 原样保留) → 重新加密 → 同步回退文件 → 校验。
set -euo pipefail

ROOT="$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel)"
cd "$ROOT"

SECRET="secrets/ai_api_key_REIKY_REI.age"
KEY="$HOME/.ssh/id_ed25519"

if [ ! -f "$SECRET" ]; then echo "找不到 $SECRET"; exit 1; fi
if [ ! -f "$KEY" ]; then echo "找不到私钥 $KEY"; exit 1; fi

# bash 的 read -s 才是"不回显"; zsh 里语义不同, 故本脚本务必用 bash 执行
read -rsp '粘贴新 GitHub token (ghp_...) → ' GH
echo
if [ -z "${GH:-}" ]; then echo "空输入, 取消"; exit 1; fi

PUB="$(grep -o 'ssh-ed25519 [A-Za-z0-9+/]*' secrets/secrets.nix | head -1)"
if [ -z "$PUB" ]; then echo "secrets/secrets.nix 里找不到公钥"; exit 1; fi

BACKUP_DIR="$HOME/.local/state/secret-backups"
mkdir -p "$BACKUP_DIR"
cp -p "$SECRET" "$BACKUP_DIR/$(basename "$SECRET").bak-$(date +%Y%m%d-%H%M%S)"
echo "已备份旧密钥到 $BACKUP_DIR (仓库外, 避免误提交)"

tmp="$(mktemp)"
trap 'shred -u "$tmp" 2>/dev/null || rm -f "$tmp"' EXIT

nix-shell -p age --run "age -d -i '$KEY' '$SECRET'" 2>/dev/null \
  | sed -E "s|^export NIX_ACCESS_TOKEN=.*|export NIX_ACCESS_TOKEN=$GH|" > "$tmp"

if ! grep -q '^export NIX_ACCESS_TOKEN=' "$tmp"; then
  echo "⚠️ 原密钥里没有 NIX_ACCESS_TOKEN 行, 中止 (避免写出奇怪的文件)"; exit 1
fi

nix-shell -p age --run "age -r '$PUB' -o '$SECRET'" < "$tmp"

if printf '%s' "$GH" > .agents/config/token 2>/dev/null; then
  chmod 600 .agents/config/token 2>/dev/null || true
else
  echo "⚠️ 回退文件 .agents/config/token 写入失败 (属主/只读?), 跳过 —— 不影响 agenix 主路径"
fi

unset GH
echo "✅ 已更新 agenix 密钥 (+ 回退文件)"
echo "校验 (值已打码):"
nix-shell -p age --run "age -d -i '$KEY' '$SECRET'" 2>/dev/null | sed -E 's/=.*/=<REDACTED>/'
echo
echo "下一步:"
echo "  1) 去 GitHub 撤销旧 token (revoke)"
echo "  2) 让 agenix 重新解密生效: sudo nixos-rebuild switch  (或重启)"
