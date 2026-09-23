#!/usr/bin/env bash
# kb-index-warm: 语料变更自动重建各根索引(签名短路, 只对变更根做全量重嵌入)
set -u
PY=/etc/profiles/per-user/Reiky-REI/bin/python3
SRV=/etc/nixos/.agents/tools/kb-mcp/server.py
LOG=$HOME/.cache/kb-warm.log
mkdir -p "$(dirname "$LOG")" /run/user/$(id -u)
exec 9>/run/user/$(id -u)/kb-warm.lock
flock -n 9 || exit 0
[ -f "$LOG" ] && [ "$(wc -c <"$LOG")" -gt 1048576 ] && : > "$LOG"

declare -a ROOTS=(/etc/nixos "$HOME" "$HOME/WorkSpace")
while IFS= read -r ag; do
  r=$(dirname "$ag")
  [ -f "$r/.agents/AGENTS.md" ] || [ -d "$r/.agents/knowledge" ] || continue
  ROOTS+=("$r")
done < <(find "$HOME/WorkSpace" -maxdepth 3 -type d -name .agents 2>/dev/null | sort -u)

valid() { [ -f "$1/.agents/AGENTS.md" ] || [ -d "$1/.agents/knowledge" ]; }

sig_of() {
  KBROOT="$1" "$PY" - <<'PYX'
import importlib.util as u, os, json
os.environ["KB_ROOT"] = os.environ["KBROOT"]
spec = u.spec_from_file_location("kbsig", "/etc/nixos/.agents/tools/kb-mcp/server.py")
m = u.module_from_spec(spec); spec.loader.exec_module(m)
sig, _ = m.scan_sources()
try: cached = json.load(open(m.CACHE)).get("sig")
except Exception: cached = None
print("SAME" if cached == sig else "CHANGED")
PYX
}

rebuild() {
  local t0=$(date +%s)
  ( cd "$1" && printf '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"warmer","version":"0"}}}\n{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"kb_stats","arguments":{}}}\n' \
      | timeout 900 "$PY" "$SRV" >/dev/null 2>&1 ) || return 1
  echo $(( $(date +%s) - t0 ))
}

echo "== $(date '+%F %T') warm start (${#ROOTS[@]} roots)" >> "$LOG"
for R in "${ROOTS[@]}"; do
  valid "$R" || continue
  st=$(sig_of "$R" 2>>"$LOG") || { echo "ERR  sig-scan $R" >> "$LOG"; continue; }
  if [ "$st" = "SAME" ]; then
    echo "SAME $R" >> "$LOG"; continue
  fi
  if secs=$(rebuild "$R"); then
    echo "BUILT $R (${secs}s)" >> "$LOG"
  else
    echo "FAIL $R (timeout/model? 下轮自动重试)" >> "$LOG"
  fi
done
echo "== $(date '+%F %T') warm done" >> "$LOG"
