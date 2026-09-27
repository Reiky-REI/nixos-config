#!/usr/bin/env bash
# agent-resume runner -- 无人值守续命任务队列消费者 (声明式部署见
# home/Reiky-REI/tools/agent-resume.nix, 本文件是唯一真相)
#
# task 文件格式(key=value):
#   id / desc / max_retries / retries / runtime_max / notify_board / payload(base64单行)
#
# 行为: 成功 → done/ + 消息板通报; 失败 → 重试至 max_retries 后进 failed/ + 失败通报。
# 防假 OK: 任务进程完成后写 per-attempt exit sentinel; 只凭 systemd-run 退出码或 task 文件存在不算成功。
set -u
BASE="${AGENT_RESUME_DIR:-$HOME/.local/state/agent-resume}"
DIALOGUE="/etc/nixos/.agents/config/dialogue.sh"
UID_=$(id -u)
mkdir -p "$BASE"/{queue,running,done,failed,log}
exec 9>"${XDG_RUNTIME_DIR:-/run/user/$UID_}/agent-resume.lock"
flock -n 9 || exit 0
shopt -s nullglob
results=()
for tf in "$BASE"/queue/*.task; do
  name=$(basename "$tf"); name=${name%.task}
  kv() { grep -m1 -E "^$1=" "$tf" | cut -d= -f2-; }
  tid=$(kv id); tid=${tid:-$name}
  desc=$(kv desc); desc=${desc:-}
  maxr=$(kv max_retries); maxr=${maxr:-3}
  ret=$(kv retries); ret=${ret:-0}
  rtm=$(kv runtime_max); rtm=${rtm:-3600}
  nfy=$(kv notify_board); nfy=${nfy:-1}
  payload=$(kv payload)
  ret=$((ret+1))
  # 防御: 老任务文件可能没有 retries= 行, sed 会静默不匹配 -> 无限重试
  grep -q '^retries=' "$tf" || echo 'retries=0' >> "$tf"
  sed -i "s/^retries=.*/retries=$ret/" "$tf"
  mv "$tf" "$BASE/running/$name.task"
  rtf="$BASE/running/$name.task"
  result_file="$BASE/running/$name-r$ret.exit"
  rm -f "$result_file"
  log="$BASE/log/${name}-r${ret}-$(date +%m%d-%H%M%S).log"
  echo "[$(date -Is)] START $tid try=$ret/$maxr $desc" >"$log"
  if XDG_RUNTIME_DIR=/run/user/$UID_ systemd-run --user --quiet --collect \
      --unit="aresume-${tid}-r${ret}-$$" --wait \
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
  rm -f "$result_file"

  if [ "$payload_rc" = "0" ]; then
    echo "[$(date -Is)] OK payload_rc=0 systemd_run_rc=$unit_rc" >>"$log"
    if [ -f "$rtf" ]; then
      mv "$rtf" "$BASE/done/"
      results+=("$tid|OK")
      if [ "$nfy" = "1" ]; then
        printf '续命任务 [%s] 已由 agent-resume 自动执行成功喵~ \n任务: %s喵 日志: %s喵~ \n' "$tid" "$desc" "$log" \
          | "$DIALOGUE" post -f watchdog -t opencode -T "agent-resume: 完成 $tid" >/dev/null 2>&1
      fi
    else
      echo "[$(date -Is)] ANOMALY: completion sentinel exists but task file is missing from running/; refusing to report OK" >>"$log"
      results+=("$tid|ANOMALY")
    fi
  else
    rc="$payload_rc"
    [ "$rc" = "INCOMPLETE" ] && rc=125
    echo "[$(date -Is)] FAIL rc=$rc payload_rc=$payload_rc systemd_run_rc=$unit_rc" >>"$log"
    if [ "$ret" -lt "$maxr" ]; then
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
