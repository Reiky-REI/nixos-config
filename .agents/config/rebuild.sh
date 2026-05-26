#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/env.sh"

if [ -z "${NIX_ACCESS_TOKEN:-}" ]; then
  echo "⚠️  NIX_ACCESS_TOKEN not set. Git fetch may fail."
  exit 1
fi

MODE="${1:-dry-activate}"

if [ "$MODE" = "switch" ]; then
  echo "⚠️  ⚠️  ⚠️  WARNING  ⚠️  ⚠️  ⚠️"
  echo "NVIDIA PRIME 系统: switch 会重启 polkit → compositor 失去 DRM master → 黑屏"
  echo "建议: 用 build + 手动 reboot 替代 switch"
  echo "按 Ctrl+C 取消，或等待 5 秒继续..."
  sleep 5
fi

sudo env \
  http_proxy="$http_proxy" \
  https_proxy="$https_proxy" \
  NIX_ACCESS_TOKEN="$NIX_ACCESS_TOKEN" \
  nixos-rebuild "$MODE" --flake /etc/nixos#NixMEOW
