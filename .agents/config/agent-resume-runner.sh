#!/usr/bin/env bash
# agent-resume runner -- 无人值守续命任务队列消费者 (声明式部署见
# home/reiky/tools/agent-resume.nix, 本文件是唯一真相)
#
# task 文件格式(key=value):
#   id / desc / max_retries / retries / runtime_max / notify_board / payload(base64单行)
#
# 行为: 成功 → done/ + 消息板通报; 失败 → 重试至 max_retries 后进 failed/ + 失败通报。
# 防假 OK: 任务进程完成后写 per-attempt exit sentinel; 只凭 systemd-run 退出码或 task 文件存在不算成功。
# 防悬挂: runner 启动时恢复上次留在 running/ 的任务; 活动 transient unit 会等待下次扫描。
set -u
BASE="${AGENT_RESUME_DIR:-$HOME/.local/state/agent-resume}"
DIALOGUE="/etc/nixos/.agents/config/dialogue.sh"
UID_=$(id -u)
mkdir -p "$BASE"/{queue,running,done,failed,log}
exec 9>"${XDG_RUNTIME_DIR:-/run/user/$UID_}/agent-resume.lock"
flock -n 9 || exit 0
shopt -s nullglob
results=()
get_value() {
  local file="$1" key="$2"
  grep -m1 -E "^${key}=" "$file" | cut -d= -f2-
}

finish_ok() {
  echo "[$(date -Is)] OK payload_rc=0${1:+ $1}" >>"$log"
  if [ -f "$rtf" ]; then
    mv "$rtf" "$BASE/done/"
    rm -f "$attempt_file" "$result_file"
    results+=("$tid|OK")
    if [ "$nfy" = "1" ]; then
      printf '续命任务 [%s] 已由 agent-resume 自动执行成功喵~ \n任务: %s喵 日志: %s喵~ \n' "$tid" "$desc" "$log" \
        | "$DIALOGUE" post -f watchdog -t opencode -T "agent-resume: 完成 $tid" >/dev/null 2>&1
    fi
  else
    echo "[$(date -Is)] ANOMALY: completion sentinel exists but task file is missing from running/; refusing to report OK" >>"$log"
    results+=("$tid|ANOMALY")
  fi
}

finish_fail() {
  local rc="$1" reason="${2:-}"
  [ -f "$log" ] || echo "[$(date -Is)] RECOVERY $tid try=$ret/$maxr $desc" >"$log"
  echo "[$(date -Is)] FAIL rc=$rc${reason:+ $reason}" >>"$log"
  rm -f "$attempt_file" "$result_file"
  if [ ! -f "$rtf" ]; then
    results+=("$tid|ANOMALY")
  elif [ "$ret" -lt "$maxr" ]; then
    mv "$rtf" "$BASE/queue/"
    results+=("$tid|RETRY($ret/$maxr)")
  else
    mv "$rtf" "$BASE/failed/"
    results+=("$tid|FAILED")
    if [ "$nfy" = "1" ]; then
      printf '续命任务 [%s] 重试 %s 次后仍失败(rc=%s) 需人工或 AI 介入喵~ \n任务: %s喵 日志: %s喵~ \n' "$tid" "$ret" "$rc" "$desc" "$log" \
        | "$DIALOGUE" post -f watchdog -t opencode -T "agent-resume: 失败 $tid" >/dev/null 2>&1
    fi
  fi
}

# 上次 runner 若在 systemd/HM reload 中途退出, 根据 sentinel 恢复结果;
# transient 仍活动时保留 running 状态, 由下一轮 timer 再收割。
for rtf in "$BASE"/running/*.task; do
  name=$(basename "$rtf"); name=${name%.task}
  tid=$(get_value "$rtf" id); tid=${tid:-$name}
  desc=$(get_value "$rtf" desc); desc=${desc:-}
  maxr=$(get_value "$rtf" max_retries); maxr=${maxr:-3}
  ret=$(get_value "$rtf" retries); ret=${ret:-0}
  nfy=$(get_value "$rtf" notify_board); nfy=${nfy:-1}
  attempt_file="$BASE/running/$name.attempt"
  attempt_unit=""
  result_file="$BASE/running/$name-r$ret.exit"
  default_result_file="$result_file"
  log=""
  if [ -f "$attempt_file" ]; then
    attempt_unit=$(get_value "$attempt_file" unit); attempt_unit=${attempt_unit:-}
    result_file=$(get_value "$attempt_file" result); result_file=${result_file:-$default_result_file}
    log=$(get_value "$attempt_file" log); log=${log:-}
  fi

  if [ -s "$result_file" ]; then
    payload_rc=$(head -n1 "$result_file")
    if [ "$payload_rc" = "0" ]; then
      finish_ok "recovered after runner restart"
    else
      rc="$payload_rc"
      [[ "$rc" =~ ^[0-9]+$ ]] || rc=125
      finish_fail "$rc" "recovered payload_rc=$payload_rc"
    fi
    continue
  fi

  active=0
  if [ -n "$attempt_unit" ]; then
    systemctl --user is-active --quiet "$attempt_unit" && active=1 || true
  else
    # Legacy attempts did not persist the unit name; match their historical PID suffix.
    unit_pattern="aresume-${tid}-r${ret}-*.service"
    systemctl --user list-units --type=service --state=active --no-legend "$unit_pattern" 2>/dev/null | grep -q . && active=1 || true
  fi
  if [ "$active" = "1" ]; then
    results+=("$tid|ACTIVE")
    continue
  fi

  log=${log:-"$BASE/log/${name}-recovery-$(date +%m%d-%H%M%S).log"}
  finish_fail 125 "recovered interrupted attempt (completion sentinel missing)"
done

for tf in "$BASE"/queue/*.task; do
  name=$(basename "$tf"); name=${name%.task}
  tid=$(get_value "$tf" id); tid=${tid:-$name}
  desc=$(get_value "$tf" desc); desc=${desc:-}
  maxr=$(get_value "$tf" max_retries); maxr=${maxr:-3}
  ret=$(get_value "$tf" retries); ret=${ret:-0}
  rtm=$(get_value "$tf" runtime_max); rtm=${rtm:-3600}
  nfy=$(get_value "$tf" notify_board); nfy=${nfy:-1}
  payload=$(get_value "$tf" payload)
  ret=$((ret+1))
  # 防御: 老任务文件可能没有 retries= 行, sed 会静默不匹配 -> 无限重试
  grep -q '^retries=' "$tf" || echo 'retries=0' >> "$tf"
  sed -i "s/^retries=.*/retries=$ret/" "$tf"
  mv "$tf" "$BASE/running/$name.task"
  rtf="$BASE/running/$name.task"
  result_file="$BASE/running/$name-r$ret.exit"
  attempt_file="$BASE/running/$name.attempt"
  attempt_unit="aresume-${tid}-r${ret}-$$.service"
  rm -f "$result_file"
  log="$BASE/log/${name}-r${ret}-$(date +%m%d-%H%M%S).log"
  printf 'unit=%s\nresult=%s\nlog=%s\n' "$attempt_unit" "$result_file" "$log" >"$attempt_file"
  echo "[$(date -Is)] START $tid try=$ret/$maxr $desc" >"$log"
  if XDG_RUNTIME_DIR=/run/user/$UID_ systemd-run --user --quiet --collect \
      --unit="$attempt_unit" --wait \
      --setenv=PAYLOAD="$payload" \
      --setenv=RESULT_FILE="$result_file" \
      --property=RuntimeMaxSec="$rtm" \
      bash -c '
        record_result() {
          rc=$?
          trap - EXIT
          tmp="${RESULT_FILE}.tmp.$$"
          printf "%s\n" "$rc" >"$tmp" && mv -f "$tmp" "$RESULT_FILE"
          exit "$rc"
        }
        trap record_result EXIT
        decoded=$(printf "%s" "$PAYLOAD" | base64 -d) || exit 126
        eval "$decoded"
      ' >>"$log" 2>&1; then
    unit_rc=0
  else
    unit_rc=$?
  fi

  payload_rc="INCOMPLETE"
  if [ -s "$result_file" ]; then
    IFS= read -r payload_rc < "$result_file" || true
  fi
  if [ "$payload_rc" = "0" ]; then
    finish_ok "systemd_run_rc=$unit_rc"
  else
    rc="$payload_rc"
    [ "$rc" = "INCOMPLETE" ] && rc=125
    finish_fail "$rc" "payload_rc=$payload_rc systemd_run_rc=$unit_rc"
  fi
done
ts=$(date -Is)
{
  echo "{"
  echo "  \"last_run\": \"$ts\","
  echo "  \"results\": ["
  first=1
  for r in "${results[@]:-}"; do
    [ -z "$r" ] && continue
    id=${r%%|*}; st=${r#*|}
    [ $first -eq 0 ] && echo ","
    printf '    {"id": "%s", "status": "%s"}' "$id" "$st"
    first=0
  done
  echo ""
  echo "  ]"
} > "$BASE/state.json.tmp"
mv "$BASE/state.json.tmp" "$BASE/state.json"
exit 0
