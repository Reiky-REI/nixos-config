#!/usr/bin/env bash
# wake-agent.sh — 编译完成后在调用者会话里"拉起 AI"
#
# 由 .agents/config/rebuild.sh 在 nixos-rebuild 结束后调用 (成功/失败都会调)。
# 作用: 用调用者 (SUDO_USER) 的身份, 在他的 Wayland 会话里开一个 Alacritty +
#       `opencode --continue`, 并弹一条桌面通知。
#
# 开关 (默认: switch 模式开, build 关):
#   - `switch` 默认拉起; `build` 默认不拉 (避免频繁打扰)
#   - 强制开/关: 环境变量 REBUILD_WAKE_AGENT=1 / =0
#     用法: sudo REBUILD_WAKE_AGENT=0 .agents/config/rebuild.sh switch
#   - 也可用标记文件 <调用者家目录>/.config/rebuild/wake-agent 强制开 (sudo 会重置环境)
#
# 参数: $1 = 模式 (build/switch/...), $2 = 退出码
set -u

MODE="${1:-build}"
RC="${2:-0}"

# ---- 定位调用者 (sudo 下的真实用户) ----
inv_user="${SUDO_USER:-$(id -un)}"
inv_uid="$(id -u "$inv_user" 2>/dev/null)" || exit 0
inv_home="$(getent passwd "$inv_user" | cut -d: -f6)"
rt="/run/user/$inv_uid"

# ---- 开关 (默认: switch 开启, build 关闭) ----
# REBUILD_WAKE_AGENT=1 强制开 / =0 强制关; 标记文件也可开
enabled=0
[ "$MODE" = "switch" ] && enabled=1
case "${REBUILD_WAKE_AGENT:-}" in
  1) enabled=1 ;;
  0) enabled=0 ;;
esac
[ -e "$inv_home/.config/rebuild/wake-agent" ] && enabled=1
[ "$enabled" = "1" ] || exit 0

# ---- 找 Wayland socket ----
wl="$(ls "$rt"/wayland-* 2>/dev/null | grep -v '\.lock$' | head -1)"
wl="${wl:+$(basename "$wl")}"

status="成功"; [ "$RC" != "0" ] && status="退出码 $RC"

# ---- 已有交互式 opencode TUI 在跑, 就不重复拉起 (只通知) ----
if pgrep -x opencode -a 2>/dev/null | grep -qE '[0-9]+ opencode$'; then
  if [ -S "$rt/bus" ]; then
    runuser -u "$inv_user" -- env XDG_RUNTIME_DIR="$rt" DBUS_SESSION_BUS_ADDRESS="unix:path=$rt/bus" \
      bash -c 'command -v notify-send >/dev/null && notify-send "$1" "$2"' _ \
      "NixOS ${MODE} 完成 (${status})" "已有 OpenCode 会话在跑, 未重复拉起" >/dev/null 2>&1 || true
  fi
  echo "wake-agent: 已有 opencode 交互会话, 跳过拉起"
  exit 0
fi

# ---- 桌面通知 (best-effort) ----
if [ -S "$rt/bus" ]; then
  runuser -u "$inv_user" -- env \
    XDG_RUNTIME_DIR="$rt" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=$rt/bus" \
    bash -c 'command -v notify-send >/dev/null && notify-send "$1" "$2"' _ \
    "NixOS ${MODE} 完成 (${status})" "正在拉起 OpenCode AI…" >/dev/null 2>&1 || true
fi

# ---- 拉起 OpenCode 终端 (脱离当前 cgroup, 后台) ----
if [ -n "$wl" ]; then
  runuser -u "$inv_user" -- env \
    XDG_RUNTIME_DIR="$rt" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=$rt/bus" \
    HOME="$inv_home" \
    WAYLAND_DISPLAY="$wl" \
    DISPLAY="${DISPLAY:-:0}" \
    PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$inv_user/bin:/usr/bin:/bin" \
    setsid alacritty --class floating_terminal -e opencode --continue \
    >/dev/null 2>&1 </dev/null &
  echo "wake-agent: 已在 $inv_user 会话拉起 opencode --continue (mode=$MODE rc=$RC)"
else
  echo "wake-agent: 未找到 Wayland socket ($rt/wayland-*), 跳过拉起"
fi
exit 0
