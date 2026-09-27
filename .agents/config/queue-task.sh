#!/usr/bin/env bash
# queue-task.sh — 把长任务放进 agent-resume 断电续命队列
#
# 为什么需要它: 裸跑后台 shell 会随 AI 会话/服务重启一起被杀 (shell cancelled),
# 长任务 (rebuild / 大镜像导入 / 批量改造) 必须走队列才算"不允许中断"喵~
#
# 用法:
#   queue-task.sh --id <唯一id> --desc <一句话> --exec '<shell 命令>' [--wake] [--max-retries N] [--notify 0|1]
#
# 参数:
#   --wake  任务结束后调用 wake-agent.sh, 在调用者 Wayland 会话里拉起
#           `opencode --continue` (即使已有会话也会新开一个 TUI)
#   --notify 1 时 (默认) 由 runner 发消息板通报
#
# 说明: task 文件格式由 .agents/config/agent-resume-runner.sh 消费 (key=value, payload=base64 单行),
# 该 runner 由 home/Reiky-REI/tools/agent-resume.nix 声明式部署为 agent-resume.service。
set -euo pipefail

BASE="${AGENT_RESUME_DIR:-$HOME/.local/state/agent-resume}"
WAKE_AGENT="/etc/nixos/.agents/config/wake-agent.sh"

id=""
desc=""
exec_cmd=""
wake=0
max_retries=3
notify=1
runtime_max=3600

while [ $# -gt 0 ]; do
  case "$1" in
    --id) id="${2:-}"; shift 2 ;;
    --desc) desc="${2:-}"; shift 2 ;;
    --exec) exec_cmd="${2:-}"; shift 2 ;;
    --wake) wake=1; shift ;;
    --max-retries) max_retries="${2:-3}"; shift 2 ;;
    --runtime-max) runtime_max="${2:-3600}"; shift 2 ;;
    --notify) notify="${2:-1}"; shift 2 ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "queue-task.sh: 未知参数 '$1'" >&2; exit 2 ;;
  esac
done

[ -n "$id" ] || { echo "queue-task.sh: 缺少 --id" >&2; exit 2; }
[ -n "$exec_cmd" ] || { echo "queue-task.sh: 缺少 --exec" >&2; exit 2; }

payload="( set -Eeuo pipefail; $exec_cmd )"
if [ "$wake" = "1" ]; then
  # 严格子 shell 的退出码保留给父 shell, 以便任务失败时仍执行强制唤醒。
  payload="{ ( set -Eeuo pipefail; $exec_cmd ); rc=\$?; WAKE_FORCE=1 MODE=agent-resume RC=\$rc '$WAKE_AGENT' agent-resume \$rc || true; exit \$rc; }"
fi

mkdir -p "$BASE/queue" "$BASE/running" "$BASE/done" "$BASE/failed" "$BASE/log"

task="$BASE/queue/$id.task"
# 注意: 必须带 `retries=0` 这一行 —— runner 用 `sed s/^retries=.*/retries=N/` 累加,
# 文件里若没有该行, sed 静默不匹配, 计数永远停在 1 -> 无限重试且永不进入失败通报喵~
printf 'id=%s\ndesc=%s\nmax_retries=%s\nretries=0\nruntime_max=%s\nnotify_board=%s\npayload=%s\n' \
  "$id" "$desc" "$max_retries" "$runtime_max" "$notify" \
  "$(printf '%s' "$payload" | base64 -w0)" \
  > "$task"

echo "queued: $task"
echo "  desc  : $desc"
echo "  wake  : $wake"
echo "  runtime_max: ${runtime_max}s (单次执行上限)"
echo "  payload: $payload"

# path unit 会在队列出现文件时秒触发; 这里不直接调用 runner, 避免和 systemd 抢锁
exit 0
