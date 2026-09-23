#!/usr/bin/env bash
# gen-kb-paths: (重)生成 kb-corpus.path 监视清单 -- 新增项目后重跑一次即可
set -euo pipefail
OUT="$HOME/.config/systemd/user/kb-corpus.path"
mkdir -p "$(dirname "$OUT")"

declare -a ROOTS=(/etc/nixos "$HOME" "$HOME/WorkSpace")
while IFS= read -r ag; do
  r=$(dirname "$ag")
  ROOTS+=("$r")
done < <(find "$HOME/WorkSpace" -maxdepth 3 -type d -name .agents 2>/dev/null | sort -u)

TMP=$(mktemp)
for R in $(printf '%s\n' "${ROOTS[@]}" | sort -u); do
  valid=0
  for f in AGENTS.md SKILLS.md MEMORY.md CLAUDE.md; do
    [ -f "$R/.agents/$f" ] && { echo "PathModified=$R/.agents/$f" >> "$TMP"; valid=1; }
  done
  for tree in knowledge memory; do
    [ -d "$R/.agents/$tree" ] && {
      find "$R/.agents/$tree" -type d | while read -r d; do echo "PathModified=$d" >> "$TMP"; done
      valid=1
    }
  done
done

{
  echo "[Unit]"
  echo "Description=kb-mcp corpus watcher (event-driven index warming)"
  echo
  echo "[Path]"
  sort -u "$TMP"
  echo
  echo "[Path]"
  echo "Unit=kb-corpus.service"
  echo "TriggerLimitIntervalSec=20s"
  echo "TriggerLimitBurst=5"
  echo
  echo "[Install]"
  echo "WantedBy=default.target"
} > "$OUT"
rm -f "$TMP"
echo "watch list: $(grep -c PathModified "$OUT") paths -> $OUT"
