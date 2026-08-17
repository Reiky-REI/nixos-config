#!/usr/bin/env bash
# dialogue.sh — 多 AI 协作消息板 CLI
#
# 结构化存储: .agents/dialogue/<id>-<from>-to-<to>-<slug>.md
# 每条消息独立文件, frontmatter 带 id/from/to/date/status/in_reply_to
#
# 用法:
#   dialogue.sh post -f opencode -t claude -T "标题" "正文..."   # 发消息
#   dialogue.sh post -f opencode -t claude -r 2026-08-16-001 -T "标题" "正文..."  # 回复某条
#   dialogue.sh list [--status pending|replied|done] [--to claude] [--from opencode] [--all]
#   dialogue.sh ack <id> [--status replied|done]                  # 标记处理状态
#   dialogue.sh show <id>                                         # 查看单条全文
#   dialogue.sh search <关键词>                                   # 全文搜索
#
# 身份: 当前 AI 通过 -f 显式指定 (opencode / claude)

set -euo pipefail

ROOT="$(git -C "$(dirname "$0")/../.." rev-parse --show-toplevel)"
DIALOGUE_DIR="$ROOT/.agents/dialogue"

# ── 工具 ──────────────────────────────────────────────────────────────
die() { echo "❌ $*" >&2; exit 1; }

# 从 frontmatter 读字段值 (第一个参数=字段名, stdin=文件内容)
read_field() {
  awk -v k="$1" '
    $0 ~ "^---$" { f++ ; next }
    f == 1 && $1 == k":" { sub("^" k ": ?", ""); print; exit }
  '
}

list_messages() {
  local status_filter="${1:-}" to_filter="${2:-}" from_filter="${3:-}"
  local files=()
  # 按 id 排序 (YYYY-MM-DD-NNN)
  while IFS= read -r f; do
    files+=("$f")
  done < <(ls "$DIALOGUE_DIR"/*.md 2>/dev/null | sort)
  for f in "${files[@]:-}"; do
    [ -f "$f" ] || continue
    local meta
    meta="$(sed -n '1,/^---$/p' "$f" | tail -n +2 | head -n -1)"
    local id from to date status title
    id="$(printf '%s' "$meta" | read_field id)"
    from="$(printf '%s' "$meta" | read_field from)"
    to="$(printf '%s' "$meta" | read_field to)"
    date="$(printf '%s' "$meta" | read_field date)"
    status="$(printf '%s' "$meta" | read_field status)"
    title="$(printf '%s' "$meta" | read_field title)"
    # 过滤
    if [ -n "$status_filter" ] && [ "$status" != "$status_filter" ]; then continue; fi
    if [ -n "$to_filter" ] && [ "$to" != "$to_filter" ]; then continue; fi
    if [ -n "$from_filter" ] && [ "$from" != "$from_filter" ]; then continue; fi
    printf '  %s  %s→%s  [%s]  %s — %s\n' \
      "$id" "$from" "$to" "$status" "$title" "$(basename "$f")"
  done
}

find_file_by_id() {
  local id="$1"
  ls "$DIALOGUE_DIR/${id}"-*.md 2>/dev/null | head -1 || true
}

# ── 子命令 ────────────────────────────────────────────────────────────
cmd_post() {
  local from="" to="" title="" reply_to="" body=""
  local args=("$@")
  while [ $# -gt 0 ]; do
    case "$1" in
      -f) from="$2"; shift 2 ;;
      -t) to="$2"; shift 2 ;;
      -T) title="$2"; shift 2 ;;
      -r) reply_to="$2"; shift 2 ;;
      -b) body="$2"; shift 2 ;;
      *) die "未知参数: $1" ;;
    esac
  done
  set -- "${args[@]}"
  [ -n "$from" ] && [ -n "$to" ] || die "必须指定 -f (from) 和 -t (to)"
  [ -n "$title" ] || title="(无标题)"
  # 正文: 优先 -b, 否则读 stdin
  if [ -z "$body" ]; then
    body="$(cat || true)"
  fi
  [ -n "$body" ] || die "正文不能为空 (用 -b 传或从 stdin 读)"

  # 生成 id: YYYY-MM-DD-NNN (递增)
  local today id seq
  today="$(date +%F)"
  local last
  last="$(ls "$DIALOGUE_DIR"/"${today}"-*.md 2>/dev/null | sort | tail -1 || true)"
  if [ -n "$last" ]; then
    seq="$(basename "$last" | sed -E 's/^[0-9-]+-([0-9]+)-.*/\1/')"
    seq="$((10#$seq + 1))"
  else
    seq=1
  fi
  id="${today}-$(printf '%03d' "$seq")"

  # slug
  local slug
  slug="$(printf '%s' "$title" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g' | cut -c1-40)"

  local file="$DIALOGUE_DIR/${id}-${from}-to-${to}-${slug}.md"
  cat > "$file" <<EOF
---
id: ${id}
date: ${today}
from: ${from}
to: ${to}
status: pending
in_reply_to: ${reply_to:-null}
title: "${title}"
---

${body}
EOF
  echo "✅ ${id} → $file"
  echo "   发往: ${to} | 主题: ${title}"
}

cmd_list() {
  local status="" to="" from="" all=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --status) status="$2"; shift 2 ;;
      --to) to="$2"; shift 2 ;;
      --from) from="$2"; shift 2 ;;
      --all) all=1; shift ;;
      *) die "未知参数: $1" ;;
    esac
  done
  echo "📬 消息列表 (${DIALOGUE_DIR})"
  if [ -z "$all" ]; then
    echo "   (默认只显示 pending, 用 --all 显示全部)"
    list_messages pending "$to" "$from"
  else
    list_messages "$status" "$to" "$from"
  fi
}

cmd_ack() {
  local id="${1:-}" new_status="done"
  shift || true
  while [ $# -gt 0 ]; do
    case "$1" in
      --status) new_status="$2"; shift 2 ;;
      *) die "未知参数: $1" ;;
    esac
  done
  [ -n "$id" ] || die "用法: dialogue.sh ack <id> [--status replied|done]"
  local file
  file="$(find_file_by_id "$id")"
  [ -n "$file" ] && [ -f "$file" ] || die "找不到消息 $id"
  case "$new_status" in
    pending|replied|done) ;;
    *) die "status 必须为 pending/replied/done" ;;
  esac
  sed -i "s/^status: .*/status: ${new_status}/" "$file"
  echo "✅ ${id} → status=${new_status}"
}

cmd_show() {
  local id="${1:-}"
  [ -n "$id" ] || die "用法: dialogue.sh show <id>"
  local file
  file="$(find_file_by_id "$id")"
  [ -n "$file" ] && [ -f "$file" ] || die "找不到消息 $id"
  cat "$file"
}

cmd_search() {
  local query="${1:-}"
  [ -n "$query" ] || die "用法: dialogue.sh search <关键词>"
  grep -rn -i --include='*.md' "$query" "$DIALOGUE_DIR" || {
    echo "无匹配"
    return 0
  }
}

# ── main ──────────────────────────────────────────────────────────────
cmd="${1:-}"
shift || true

[ -d "$DIALOGUE_DIR" ] || mkdir -p "$DIALOGUE_DIR"

case "$cmd" in
  post)  cmd_post "$@" ;;
  list)  cmd_list "$@" ;;
  ack)   cmd_ack "$@" ;;
  show)  cmd_show "$@" ;;
  search) cmd_search "$@" ;;
  help|--help|-h)
    sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
    ;;
  *) die "未知命令: $cmd (post/list/ack/show/search/help)" ;;
esac
