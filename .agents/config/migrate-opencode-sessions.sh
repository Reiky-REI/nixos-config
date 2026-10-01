#!/usr/bin/env bash
# Re-home OpenCode V2 sessions after a user home-directory rename喵~
set -euo pipefail

DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=1
  shift
fi

OLD_HOME="${1:-/home/Reiky-REI}"
NEW_HOME="${2:-/home/reiky}"

if [ "$(id -u)" = 0 ]; then
  printf '请以登录后的普通用户运行,不要使用 root 喵~\n' >&2
  exit 1
fi

if [ "$OLD_HOME" = "$NEW_HOME" ] || [ "${OLD_HOME#/}" = "$OLD_HOME" ] || [ "${NEW_HOME#/}" = "$NEW_HOME" ]; then
  printf '旧家目录和新家目录必须是不同的绝对路径喵~\n' >&2
  exit 2
fi

if [ "${HOME%/}" != "${NEW_HOME%/}" ]; then
  printf '请先以新用户登录,让 HOME 与 %s 一致喵~\n' "$NEW_HOME" >&2
  exit 2
fi
if [ ! -d "$NEW_HOME" ]; then
  printf '新家目录不存在: %s 喵~\n' "$NEW_HOME" >&2
  exit 2
fi

command -v opencode >/dev/null 2>&1 || {
  printf '需要 OpenCode V2 喵~\n' >&2
  exit 127
}
command -v python3 >/dev/null 2>&1 || {
  printf '需要 python3 来分页读取 OpenCode API 喵~\n' >&2
  exit 127
}

python3 - "$OLD_HOME" "$NEW_HOME" "$DRY_RUN" <<'PY'
import json
import subprocess
import sys
import urllib.parse

old_home, new_home, dry_run = sys.argv[1], sys.argv[2], sys.argv[3] == "1"


def api(method, path, body=None):
    command = ["opencode", "api", method, path]
    if body is not None:
        command.extend(["--data", json.dumps(body, separators=(",", ":"))])
    result = subprocess.run(command, text=True, capture_output=True)
    if result.returncode:
        sys.stderr.write(result.stderr)
        raise SystemExit(result.returncode)
    if not result.stdout.strip():
        return None
    return json.loads(result.stdout)


def sessions_for(directory):
    found = []
    cursor = None
    seen_cursors = set()
    while True:
        query = [("directory", directory), ("limit", "1000"), ("order", "asc")]
        if cursor:
            query.append(("cursor", cursor))
        page = api("get", "/api/session?" + urllib.parse.urlencode(query))
        for session in page.get("data", []):
            location = session.get("location") or {}
            if location.get("directory") == directory:
                found.append(session["id"])
        next_cursor = (page.get("cursor") or {}).get("next")
        if not next_cursor or next_cursor in seen_cursors:
            break
        seen_cursors.add(next_cursor)
        cursor = next_cursor
    return found


ids = sessions_for(old_home)
if not ids:
    print(f"旧路径没有剩余 OpenCode 会话喵~")
    raise SystemExit(0)

print(f"发现 {len(ids)} 个 OpenCode 会话需要迁移喵~")
for session_id in ids:
    if dry_run:
        print(f"预览迁移 {session_id} -> {new_home} 喵~")
        continue
    api("post", f"/api/session/{urllib.parse.quote(session_id, safe='')}/move", {"directory": new_home})
    info = api("get", f"/api/session/{urllib.parse.quote(session_id, safe='')}")
    location = (info or {}).get("location") or {}
    if location.get("directory") != new_home:
        raise SystemExit(f"会话 {session_id} 迁移后路径校验失败喵~")
    print(f"已迁移 {session_id} 喵~")

if not dry_run and sessions_for(old_home):
    raise SystemExit(f"旧路径仍有会话未迁移: {old_home} 喵~")

print("OpenCode 会话路径迁移校验通过喵~")
PY
