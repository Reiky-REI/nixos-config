#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/env.sh"

# 2026-11-15: 固定在仓库根构建喵~
# 原因: nix 把构建结果写成调用者 cwd 下的 ./result, 而每个 result 会被自动登记成
# gcroot(/nix/var/nix/gcroots/auto/...); 曾有一次降权进程从 `/` 起构建, 留下 `/result`
# 钉住整个旧闭包 21G 三周 (审计工具: .agents/config/nix-gcroot-audit.sh)喵~
cd /etc/nixos

if [ -z "${NIX_ACCESS_TOKEN:-}" ]; then
  echo "⚠️  NIX_ACCESS_TOKEN not set. Git fetch may fail."
  exit 1
fi

MODE="${1:-dry-activate}"
VERBOSE="${2:-}"

# 镜像源（USTC + SJTU 优先，cache.nixos.org 兜底）
# 2026-11-15: 去掉 TUNA —— nix-channels/store 的 nix-cache-info 返回 403,
# 排在首位只会让每次 narinfo 查询先白跑一趟 (见 modules/common/default.nix 注释)
SUBSTITUTERS="https://mirrors.ustc.edu.cn/nix-channels/store https://mirror.sjtu.edu.cn/nix-channels/store https://cache.nixos.org"

ARGS=(
  "$MODE"
  --flake /etc/nixos#NixMEOW
  --option substituters "$SUBSTITUTERS"
  --option access-tokens "github.com=${NIX_ACCESS_TOKEN}"
)

if [ "$VERBOSE" = "--verbose" ] || [ "$VERBOSE" = "-v" ]; then
  ARGS+=(--print-build-logs)
fi

if [ "$MODE" = "switch" ]; then
  echo "⚠️  ⚠️  ⚠️  WARNING  ⚠️  ⚠️  ⚠️"
  echo "NVIDIA PRIME 系统: switch 会重启 polkit → compositor 失去 DRM master → 黑屏"
  echo "建议: 用 build + 手动 reboot 替代 switch"
  echo "按 Ctrl+C 取消，或等待 5 秒继续..."
  sleep 5
fi

rc=0
sudo env \
  http_proxy="$http_proxy" \
  https_proxy="$https_proxy" \
  NIX_ACCESS_TOKEN="$NIX_ACCESS_TOKEN" \
  nixos-rebuild "${ARGS[@]}" || rc=$?


# 构建完成顺手体检「僵尸引用链」(只读, 发现问题才输出)喵~
if [ -x /etc/nixos/.agents/config/nix-gcroot-audit.sh ]; then
  /etc/nixos/.agents/config/nix-gcroot-audit.sh --quiet || true
fi

# 编译结束后拉起 AI (opt-in):
#   REBUILD_WAKE_AGENT=1  或  调用者家目录 ~/.config/rebuild/wake-agent 标记存在
# 成功/失败都会尝试; 未开启则直接跳过。
if [ -x "$SCRIPT_DIR/wake-agent.sh" ]; then
  "$SCRIPT_DIR/wake-agent.sh" "$MODE" "$rc" || true
fi

# switch/test/boot 会新建 system profile 世代 — 成功后顺手预览世代保留状态。
# prune 是空间闸门式保留 (规则与动机见 modules/common/nix-prune.nix 头注释):
# 默认 dry-run, 只在剩余空间不够时给出可删清单, 不自动删除。
if [ "$rc" -eq 0 ]; then
  case "$MODE" in
    switch | test | boot)
      if [ -x /run/current-system/sw/bin/nix-prune-generations ]; then
        echo "==> 世代保留预览 (空间够不删; 详见 README「世代保留策略」)"
        sudo /run/current-system/sw/bin/nix-prune-generations || true
      fi
      ;;
  esac
fi

exit "$rc"
