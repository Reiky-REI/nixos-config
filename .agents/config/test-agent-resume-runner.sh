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

echo "agent-resume runner regression checks passed"
