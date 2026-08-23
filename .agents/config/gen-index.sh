#!/usr/bin/env bash
# gen-index.sh — 知识索引自动生成器  用法: gen-index.sh [--check]
set -euo pipefail
ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2>/dev/null || echo "$(cd "$(dirname "$0")/../.." && pwd)")"
KNOW="$ROOT/.agents/knowledge"
CHECK=0; [ "${1:-}" = "--check" ] && CHECK=1
read_field() { awk -v k="$1" '$0 ~ "^---$" { f++; next } f == 1 && $1 == k":" { sub("^" k ": ?", ""); print; exit }'; }
meta_of() {
  local f="$1" date tags title
  if [ -r "$f" ]; then
    date="$(read_field date < "$f")"
    tags="$(read_field tags < "$f" | tr -d '[]')"
    title="$(grep -m1 '^# ' "$f" || true)"
    title="$(printf '%s
' "$title" | sed -e 's/^#[[:space:]]*//' -e 's/^复盘: *//' -e 's/^排查: *//' -e 's/^决策: *//')"
  fi
  [ -n "$date" ] || date="$(basename "$f" | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}' || echo unknown)"
  [ -n "$title" ] || title="(无标题)"
  [ -n "$tags" ] || tags="未编目"
  printf '%s|%s|%s
' "$date" "$tags" "$title"
}
rows=(); n=0; unreadable=()
for f in "$KNOW"/retros/*.md; do
  base="$(basename "$f")"; [ "$base" = ".retros-index.md" ] && continue
  if [ ! -r "$f" ]; then unreadable+=("$base"); continue; fi
  IFS='|' read -r date tags title < <(meta_of "$f")
  rows+=("${date}|${base}|${tags}"); n=$((n+1))
done
idx="$KNOW/retros/.retros-index.md"; tmp="$(mktemp)"
{
  echo "# Retros 索引 (自动生成 — 由 .agents/config/gen-index.sh 维护, 勿手改)"
  echo; echo "共 ${n} 篇, 按日期倒序"; echo
  echo "| 复盘 | 日期 | 标签 |"; echo "|------|------|------|"
  printf '%s
' "${rows[@]}" | sort -t'|' -k1,1r | while IFS='|' read -r d b t; do
    printf '| [%s](%s) | %s | %s |
' "$b" "$b" "$d" "$t"
  done
  if [ ${#unreadable[@]} -gt 0 ]; then
    echo; echo "> ⚠️ 以下文件不可读 (属主/权限问题), 未纳入索引:"
    printf '> - %s
' "${unreadable[@]}"
  fi
} > "$tmp"
if [ "$CHECK" = 1 ]; then
  diff -q "$tmp" "$idx" >/dev/null || { echo "❌ retros 索引过期"; exit 1; }
else
  mv "$tmp" "$idx"; echo "OK retros 索引已重生成 (${n} 篇)"
fi
INDEX="$KNOW/INDEX.md"
sed -i -E "s/（共 [0-9]+ 篇）/（共 ${n} 篇）/" "$INDEX"
dtbl="$(mktemp)"
{
  echo "## 决策索引"
  echo "| 文件 | 标签 | 日期 |"; echo "|------|------|------|"
  for f in "$KNOW"/decisions/*.md; do
    base="$(basename "$f")"; [ -r "$f" ] || continue
    IFS='|' read -r d t _ < <(meta_of "$f")
    printf '| [%s](decisions/%s) | %s | %s |
' "$base" "$base" "$t" "$d"
  done
  echo
} > "$dtbl"
dtmp="$(mktemp)"
awk -v repl="$dtbl" '/^## 决策索引$/ { inblk=1; while ((getline l < repl) > 0) print l; close(repl); next } /^## / && inblk { inblk=0 } !inblk { print }' "$INDEX" > "$dtmp"
if [ "$CHECK" = 1 ]; then
  diff -q "$dtmp" "$INDEX" >/dev/null || { echo "❌ INDEX.md 过期"; exit 1; }
else
  mv "$dtmp" "$INDEX"; echo "OK INDEX.md 已同步"
fi
echo "完成: 共 ${n} 篇复盘$( [ ${#unreadable[@]} -gt 0 ] && echo ", ${#unreadable[@]} 篇不可读待修权限" )"
