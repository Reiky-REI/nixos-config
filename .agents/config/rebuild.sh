#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/env.sh"

if [ -z "${NIX_ACCESS_TOKEN:-}" ]; then
  echo "⚠️  NIX_ACCESS_TOKEN not set. Git fetch may fail."
  exit 1
fi

MODE="${1:-dry-activate}"

sudo env \
  http_proxy="$http_proxy" \
  https_proxy="$https_proxy" \
  NIX_ACCESS_TOKEN="$NIX_ACCESS_TOKEN" \
  nixos-rebuild "$MODE" --flake /etc/nixos#NixMEOW \
  --option substituters "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store https://mirrors.ustc.edu.cn/nix-channels/store https://cache.nixos.org" \
  --option access-tokens "github.com=${NIX_ACCESS_TOKEN}"
