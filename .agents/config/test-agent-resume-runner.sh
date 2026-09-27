#!/usr/bin/env bash
# Regression checks for payload completion and strict queue command handling.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RUNNER="$ROOT/.agents/config/agent-resume-runner.sh"
QUEUE="$ROOT/.agents/config/queue-task.sh"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/runtime"

cat >"$TMP/bin/systemd-run" <<'FAKE_SYSTEMD_RUN'
#!/usr/bin/env bash
if [ "${FAKE_SYSTEMD_RUN_MODE:-execute}" = "stopped-zero" ]; then
  # systemd-run --wait may return 0 when the transient unit is externally stopped.
  exit 0
fi
while [ "$#" -gt 0 ]; do
  case "$1" in
    --setenv=PAYLOAD=*) PAYLOAD=${1#--setenv=PAYLOAD=}; export PAYLOAD; shift ;;
    --setenv=RESULT_FILE=*) RESULT_FILE=${1#--setenv=RESULT_FILE=}; export RESULT_FILE; shift ;;
    --user|--quiet|--collect|--wait|--unit=*|--property=*) shift ;;
    *) break ;;
  esac
done
exec "$@"
FAKE_SYSTEMD_RUN
chmod +x "$TMP/bin/systemd-run"

cat >"$TMP/bin/systemctl" <<'FAKE_SYSTEMCTL'
#!/usr/bin/env bash
[ "${1:-}" = "--user" ] && shift
command=${1:-}
shift || true
unit="${@: -1}"
case "$command" in
  is-active)
    [ -n "${FAKE_ACTIVE_UNIT:-}" ] && [ "$unit" = "$FAKE_ACTIVE_UNIT" ] && exit 0
    exit 3
    ;;
  list-units)
    if [ -n "${FAKE_ACTIVE_UNIT:-}" ] && [[ "$FAKE_ACTIVE_UNIT" == $unit ]]; then
      printf '%s loaded active running fake\n' "$FAKE_ACTIVE_UNIT"
    fi
    ;;
esac
FAKE_SYSTEMCTL
chmod +x "$TMP/bin/systemctl"

run_case() {
  local id="$1" mode="$2" command="$3" base="$TMP/$1"
  mkdir -p "$base"
  AGENT_RESUME_DIR="$base" \
    "$QUEUE" --id "$id" --desc "runner regression: $id" \
      --exec "$command" --max-retries 1 --notify 0 >/dev/null
  AGENT_RESUME_DIR="$base" \
    XDG_RUNTIME_DIR="$TMP/runtime" \
    FAKE_SYSTEMD_RUN_MODE="$mode" \
    TEST_MARKER="$TMP/$id.marker" \
    PATH="$TMP/bin:$PATH" \
    "$RUNNER"
}

run_case success execute 'printf success > "$TEST_MARKER"'
test "$(cat "$TMP/success.marker")" = success
test -f "$TMP/success/done/success.task"
grep -q 'OK payload_rc=0' "$TMP/success/log/"*.log

run_case strict-failure execute 'false; printf should-not-run > "$TEST_MARKER"'
test ! -e "$TMP/strict-failure.marker"
test -f "$TMP/strict-failure/failed/strict-failure.task"
grep -q 'FAIL rc=1 payload_rc=1' "$TMP/strict-failure/log/"*.log

run_case stopped-zero stopped-zero 'printf should-not-run > "$TEST_MARKER"'
test ! -e "$TMP/stopped-zero.marker"
test ! -e "$TMP/stopped-zero/done/stopped-zero.task"
test -f "$TMP/stopped-zero/failed/stopped-zero.task"
grep -q 'FAIL rc=125 payload_rc=INCOMPLETE' "$TMP/stopped-zero/log/"*.log

AGENT_RESUME_DIR="$TMP/wake" "$QUEUE" --id wake-payload --desc 'wake payload syntax' \
  --exec 'false' --wake --notify 0 >/dev/null
wake_payload=$(base64 -d < <(sed -n 's/^payload=//p' "$TMP/wake/queue/wake-payload.task"))
grep -q 'WAKE_FORCE=1' <<<"$wake_payload"
bash -n -c "$wake_payload"

# A runner reload can leave a task in running/. Inactive, incomplete attempts retry;
# attempts with a success sentinel are finalized; active transients are not duplicated.
recovered="$TMP/recovered"
mkdir -p "$recovered/running"
printf 'id=recovered\ndesc=recovered interrupted task\nmax_retries=2\nretries=1\nnotify_board=0\npayload=%s\n' \
  "$(printf '%s' 'printf recovered > "$TEST_MARKER"' | base64 -w0)" \
  > "$recovered/running/recovered.task"
AGENT_RESUME_DIR="$recovered" XDG_RUNTIME_DIR="$TMP/runtime" TEST_MARKER="$TMP/recovered.marker" \
  FAKE_SYSTEMD_RUN_MODE=execute PATH="$TMP/bin:$PATH" "$RUNNER"
test "$(cat "$TMP/recovered.marker")" = recovered
test -f "$recovered/done/recovered.task"
grep -q '^retries=2$' "$recovered/done/recovered.task"

completed="$TMP/recovered-completed"
mkdir -p "$completed/running"
printf 'id=recovered-completed\ndesc=sentinel survived runner restart\nmax_retries=2\nretries=1\nnotify_board=0\n' \
  > "$completed/running/recovered-completed.task"
printf 'unit=aresume-recovered-completed-r1-old.service\nresult=%s/running/recovered-completed-r1.exit\nlog=%s/recovered.log\n' \
  "$completed" "$completed" > "$completed/running/recovered-completed.attempt"
printf '0\n' > "$completed/running/recovered-completed-r1.exit"
AGENT_RESUME_DIR="$completed" XDG_RUNTIME_DIR="$TMP/runtime" PATH="$TMP/bin:$PATH" "$RUNNER"
test -f "$completed/done/recovered-completed.task"
grep -q 'recovered after runner restart' "$completed/recovered.log"

active="$TMP/active"
mkdir -p "$active/running"
printf 'id=active\ndesc=transient still running\nmax_retries=2\nretries=1\nnotify_board=0\n' \
  > "$active/running/active.task"
printf 'unit=aresume-active-r1-old.service\nresult=%s/running/active-r1.exit\nlog=%s/active.log\n' \
  "$active" "$active" > "$active/running/active.attempt"
AGENT_RESUME_DIR="$active" XDG_RUNTIME_DIR="$TMP/runtime" FAKE_ACTIVE_UNIT=aresume-active-r1-old.service \
  PATH="$TMP/bin:$PATH" "$RUNNER"
test -f "$active/running/active.task"
test ! -e "$active/queue/active.task"

legacy="$TMP/legacy-running"
mkdir -p "$legacy/running"
printf 'id=legacy\ndesc=pre-sidecar interrupted task\nmax_retries=1\nretries=1\nnotify_board=0\n' \
  > "$legacy/running/legacy.task"
AGENT_RESUME_DIR="$legacy" XDG_RUNTIME_DIR="$TMP/runtime" PATH="$TMP/bin:$PATH" "$RUNNER"
test -f "$legacy/failed/legacy.task"
grep -q 'completion sentinel missing' "$legacy/log/legacy-recovery-"*.log

echo "agent-resume runner regression checks passed"
