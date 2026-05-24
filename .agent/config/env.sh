#!/usr/bin/env bash
# Source this file to set up proxy and GitHub token for Nix builds.
set -a

# 优先使用 agenix 解密的环境变量（日常 rebuild 走这里）
if [ -f /run/agenix/ai_api_key_REIKY_REI ]; then
  source /run/agenix/ai_api_key_REIKY_REI
fi

# 回退到 token 文件（首次或 agenix 不可用时）
TOKEN_FILE="$(dirname "$0")/token"
if [ -z "${NIX_ACCESS_TOKEN:-}" ] && [ -f "$TOKEN_FILE" ]; then
  NIX_ACCESS_TOKEN="$(cat "$TOKEN_FILE")"
fi

http_proxy=http://127.0.0.1:7897
https_proxy=http://127.0.0.1:7897
set +a
