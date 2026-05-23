#!/usr/bin/env bash
# Source this file to set up proxy and GitHub token for Nix builds.
set -a
TOKEN_FILE="$(dirname "$0")/token"
if [ -f "$TOKEN_FILE" ]; then
  NIX_ACCESS_TOKEN="$(cat "$TOKEN_FILE")"
fi
http_proxy=http://127.0.0.1:7897
https_proxy=http://127.0.0.1:7897
set +a
