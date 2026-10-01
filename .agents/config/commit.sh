#!/usr/bin/env bash
# AI 专用 commit + push 脚本喵~
# 
# 用 opencode[bot] 身份提交, bot token 推送
# 推送当前 feature branch,不固定推 main 喵~
# 写法:  .agents/config/commit.sh -m "type: 描述"
#        .agent/config/commit.sh --amend          # 修正上次 AI 提交

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOKEN_FILE="${BOT_TOKEN_FILE:-$SCRIPT_DIR/bot-token}"

if [ ! -f "$TOKEN_FILE" ]; then
  echo "⚠️  bot-token not found. Run as normal user:"
  echo "   git commit $@"
  exit 1
fi

BOT_TOKEN="$(cat "$TOKEN_FILE")"
REPO="Reiky-REI/nixos-config"
CURRENT_BRANCH="$(git symbolic-ref --quiet --short HEAD)" || {
  echo "Cannot push an OpenCode commit from detached HEAD; switch to a feature branch first" >&2
  exit 1
}

git -c user.name="opencode[bot]" \
    -c user.email="opencode[bot]@users.noreply.github.com" \
    commit "$@"

git push \
  https://oauth2:"${BOT_TOKEN}"@github.com/"${REPO}".git \
  "HEAD:refs/heads/${CURRENT_BRANCH}"
