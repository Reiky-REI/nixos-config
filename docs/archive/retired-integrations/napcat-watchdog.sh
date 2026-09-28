#!/usr/bin/env bash
# NapCat + AstrBot 守护进程
# 每小时检查一次服务状态，未运行则重启；累计两次重启失败则触发 dsh-tui 修复
set -euo pipefail

STATE_DIR="$HOME/.local/state/napcat-watchdog"
LOG="$STATE_DIR/watchdog.log"
RESTART_COUNT_FILE="$STATE_DIR/restart_count"
SERVICES=("astrabot.service" "napcat.service")
MAX_RESTART=2

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG"; }

mkdir -p "$STATE_DIR"

# 读取累计重启次数
restart_count=0
[ -f "$RESTART_COUNT_FILE" ] && restart_count=$(cat "$RESTART_COUNT_FILE")

check_and_restart() {
  local svc="$1"
  local status
  status=$(systemctl --user is-active "$svc" 2>/dev/null || true)
  if [ "$status" = "active" ]; then
    return 0
  fi
  log "[WARN] $svc 未运行 (status=$status)，尝试重启..."
  systemctl --user restart "$svc" 2>/dev/null
  sleep 5
  status=$(systemctl --user is-active "$svc" 2>/dev/null || true)
  if [ "$status" = "active" ]; then
    log "[OK] $svc 重启成功"
    return 0
  else
    log "[ERROR] $svc 重启失败 (status=$status)"
    return 1
  fi
}

# 检查所有服务
failed=0
for svc in "${SERVICES[@]}"; do
    check_and_restart "$svc" || failed=$((failed + 1))
done

if [ "$failed" -eq 0 ]; then
  log "[OK] 所有服务正常运行"
  echo 0 > "$RESTART_COUNT_FILE"
  exit 0
fi

# 有服务失败，累计计数
restart_count=$((restart_count + 1))
echo "$restart_count" > "$RESTART_COUNT_FILE"
log "[WARN] 本轮有 $failed 个服务重启失败，累计 $restart_count 次"

if [ "$restart_count" -ge "$MAX_RESTART" ]; then
  log "[CRITICAL] 累计 $restart_count 次重启未修复，触发 dsh-tui 修复..."
  echo 0 > "$RESTART_COUNT_FILE"
  # 拉起 dsh-tui 进程尝试修复
  if command -v dsh-tui &>/dev/null; then
    nohup dsh-tui --action repair >> "$LOG" 2>&1 &
    log "[INFO] dsh-tui repair 已启动 (pid $!)"
  else
    log "[ERROR] dsh-tui 未安装，无法自动修复"
  fi
fi
