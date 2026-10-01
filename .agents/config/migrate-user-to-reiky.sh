#!/usr/bin/env bash
# migrate-user-to-reiky.sh — rename system user Reiky-REI -> reiky
#
# Background / plan:
#   .agents/requests/pending/2026-10-01-user-identity-rename-to-reiky.md
#
# Usage (must be root; graphical session must be logged out):
#   NixMEOW:
#     1. Log out of the graphical session (back to ly)
#     2. Ctrl+Alt+F3 -> log in as Reiky-REI
#     3. sudo -i
#     4. bash /etc/nixos/.agents/config/migrate-user-to-reiky.sh
#     5. Reboot only after exit status 0, then log in as reiky
#   NixMEOW-WSL:
#     sudo -i bash /etc/nixos/.agents/config/migrate-user-to-reiky.sh NixMEOW-WSL
#
# If the script exits nonzero, do not blindly reboot into the old generation喵~
# Stay at the root TTY, inspect the saved log, fix the cause, and rerun喵~
# Each root run saves stdout and stderr in /var/log/meow-user-migration/喵~
#
# Why not `usermod`? usermod refuses while ANY process of the user exists
# ("user X is currently used by process N") — the lingering systemd --user
# manager and user services always qualify. This script edits the account
# databases directly (uid stays 1002) and moves the home dir with mv.
# Idempotent: safe to rerun after a partial failure.
set -euo pipefail

OLD=Reiky-REI
NEW=reiky
OLD_HOME=/home/$OLD
NEW_HOME=/home/$NEW
HOST="${1:-NixMEOW}"
LOG_DIR=/var/log/meow-user-migration
LOG_FILE=""
PHASE=preflight

log() { printf '[migrate] %s\n' "$*"; }
die() {
  printf '[migrate:error] %s\n' "$*" >&2
  if [ -n "$LOG_FILE" ]; then
    printf '[migrate:error] full log: %s\n' "$LOG_FILE" >&2
  fi
  exit 1
}
report_exit() {
  local status=$?
  if [ "$status" -ne 0 ] && [ -n "$LOG_FILE" ]; then
    printf '[migrate:error] stopped in phase=%s exit=%s; full log: %s 喵~\n' \
      "$PHASE" "$status" "$LOG_FILE" >&2
  fi
}

[ "$(id -u)" = 0 ] || die "must run as root (sudo -i)"
umask 077
mkdir -p "$LOG_DIR" || die "cannot create migration log directory $LOG_DIR"
chmod 0700 "$LOG_DIR" || die "cannot secure migration log directory $LOG_DIR"
LOG_FILE="$LOG_DIR/${OLD}-to-${NEW}-$(date +%Y%m%d-%H%M%S)-$$.log"
: > "$LOG_FILE" || die "cannot create migration log $LOG_FILE"
chmod 0600 "$LOG_FILE" || die "cannot secure migration log $LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1
trap report_exit EXIT
log "host=$HOST old_home=$OLD_HOME new_home=$NEW_HOME log=$LOG_FILE"

# 0) repo config must already use the new name
PHASE=config-check
grep -q "username = \"$NEW\"" /etc/nixos/users.nix || die "users.nix is not updated to $NEW yet - merge chore/user-rename-to-reiky first"

ACCOUNT_RENAMED=0
id "$NEW" >/dev/null 2>&1 && ACCOUNT_RENAMED=1
HOME_MOVED=0
[ -d "$NEW_HOME" ] && HOME_MOVED=1

if [ "$ACCOUNT_RENAMED" = 1 ] && [ "$HOME_MOVED" = 1 ] && ! id "$OLD" >/dev/null 2>&1; then
  log "already migrated - skipping rename, going straight to activation/fixups"
else
  id "$OLD" >/dev/null 2>&1 || die "user $OLD not found (and not fully migrated?)"
  id "$NEW" >/dev/null 2>&1 && die "user $NEW already exists but $OLD_HOME still present - half-migrated, inspect manually"

  pgrep -u "$OLD" -x niri >/dev/null 2>&1 && die "niri is still running - log out of the graphical session first"

  # 1) unmount anything inside the home dir (NAS CIFS)
  PHASE=unmount-nas
  if mountpoint -q "$OLD_HOME/nas"; then
    log "stopping nas-mount and unmounting $OLD_HOME/nas"
    systemctl stop nas-mount.service 2>/dev/null || true
    umount "$OLD_HOME/nas" || die "failed to unmount NAS - check manually and rerun"
  fi

  # 2) move the home directory (same fs -> atomic rename)
  PHASE=home-move
  if [ "$HOME_MOVED" = 0 ]; then
    [ -d "$OLD_HOME" ] || die "$OLD_HOME not found"
    [ ! -e "$NEW_HOME" ] || die "$NEW_HOME already exists - aborting"
    log "mv $OLD_HOME -> $NEW_HOME"
    mv "$OLD_HOME" "$NEW_HOME"
  else
    log "home dir already moved - continuing"
  fi

  # 3) rename in account databases (backup first; uid unchanged)
  PHASE=account-databases
  if [ "$ACCOUNT_RENAMED" = 0 ]; then
    BK="/root/meow-user-migrate-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BK"
    for f in /etc/passwd /etc/shadow /etc/group /etc/gshadow; do
      [ -f "$f" ] && cp -a "$f" "$BK/"
    done
    log "renaming account in /etc/passwd|shadow|group|gshadow (backup: $BK)"
    sed -i "s/^$OLD:/$NEW:/; s|:/home/$OLD:|:/home/$NEW:|" /etc/passwd
    sed -i "s/^$OLD:/$NEW:/" /etc/shadow
    sed -i "s/\b$OLD\b/$NEW/g" /etc/group /etc/gshadow
    grep -q "^$NEW:" /etc/passwd || die "passwd rename failed - restore from $BK and investigate"
    id "$NEW" >/dev/null 2>&1 || die "id $NEW still fails after passwd edit"
    if [ -f "/var/spool/mail/$OLD" ]; then
      mv "/var/spool/mail/$OLD" "/var/spool/mail/$NEW"
    fi
  fi
fi

# 4) podman subuid/subgid: keep the original range when possible (idempotent)
PHASE=subuid-subgid
for f in /etc/subuid /etc/subgid; do
  [ -f "$f" ] || continue
  if ! grep -q "^$NEW:" "$f" && grep -q "^$OLD:" "$f"; then
    sed -i "s/^$OLD:/$NEW:/" "$f"
  else
    sed -i "/^$OLD:/d" "$f"
  fi
done

# 5) linger (systemd user manager without login) moves to the new name
PHASE=linger
loginctl enable-linger "$NEW" 2>/dev/null || true
rm -f "/var/lib/systemd/linger/$OLD"

# 6) activate the new configuration (login/home/homeProfile/envKey all updated)
PHASE=nixos-rebuild-switch
[ -r "$NEW_HOME/.ssh/id_ed25519" ] || die "new home SSH identity is missing or unreadable at $NEW_HOME/.ssh/id_ed25519 喵~"
NEW_ACCOUNT_HOME=$(getent passwd "$NEW" | cut -d: -f6)
[ "$NEW_ACCOUNT_HOME" = "$NEW_HOME" ] || die "account $NEW has home '$NEW_ACCOUNT_HOME', expected '$NEW_HOME' 喵~"
log "nixos-rebuild switch --flake /etc/nixos#$HOST"
if ! nixos-rebuild switch --flake "/etc/nixos#$HOST"; then
  die "switch failed after account/home rename. Do not blindly reboot into the old generation; stay at the root TTY, inspect the saved log, fix the cause, and rerun (idempotent) 喵~"
fi

# 7) fix absolute paths in non-declarative files inside the home dir
PHASE=home-path-fixups
UID_NEW=$(id -u "$NEW")
GID_NEW=$(id -g "$NEW")
log "fixing absolute paths inside home"
fix_file() {
  local f=$1 owner
  [ -f "$f" ] || return 0
  grep -q "$OLD_HOME" "$f" || return 0
  owner=$(stat -c '%u:%g' "$f")
  sed -i "s|$OLD_HOME|$NEW_HOME|g" "$f"
  chown "$owner" "$f"
  log "  fixed: $f"
}
fix_file "$NEW_HOME/.claude/settings.json"
fix_file "$NEW_HOME/.claude/plugins/installed_plugins.json"
fix_file "$NEW_HOME/.claude/plugins/known_marketplaces.json"
fix_file "$NEW_HOME/.dsh/storages/workspace.json"
fix_file "$NEW_HOME/.cache/noctalia/wallpapers.json"
fix_file "$NEW_HOME/.config/Code/User/globalStorage/storage.json"
while IFS= read -r f; do
  fix_file "$f"
done < <(grep -rl "$OLD_HOME" "$NEW_HOME/.claude/jobs" 2>/dev/null || true)

fix_claude_local_settings() {
  local f="$NEW_HOME/.claude/settings.local.json" owner
  [ -f "$f" ] || return 0
  grep -q "$OLD_HOME" "$f" || return 0
  owner=$(stat -c '%u:%g' "$f")
  cp -a "$f" "${LOG_FILE}.settings.local.json.bak"
  chmod 0600 "${LOG_FILE}.settings.local.json.bak"
  python3 - "$f" "$OLD_HOME" "$NEW_HOME" "$OLD" "$NEW" <<'PY'
import json
import os
import stat
import sys
import tempfile

path, old_home, new_home, old_name, new_name = sys.argv[1:]
with open(path, encoding="utf-8") as source:
    data = json.load(source)

old_project_memory = f"/.claude/projects/-home-{old_name}/memory)"
drop = object()

def rewrite(value):
    if isinstance(value, str):
        if value.startswith("Bash(rm ") and old_project_memory in value:
            return drop
        if value.startswith("Bash(ln -s ") and old_project_memory in value:
            return drop
        return value.replace(old_home, new_home).replace(
            f"-home-{old_name}", f"-home-{new_name}"
        )
    if isinstance(value, list):
        result = []
        for item in value:
            item = rewrite(item)
            if item is not drop:
                result.append(item)
        return result
    if isinstance(value, dict):
        result = {}
        for key, item in value.items():
            item = rewrite(item)
            if item is not drop:
                result[key] = item
        return result
    return value

data = rewrite(data)
metadata = os.stat(path)
fd, temporary = tempfile.mkstemp(prefix=".settings.local.", dir=os.path.dirname(path))
try:
    with os.fdopen(fd, "w", encoding="utf-8") as target:
        json.dump(data, target, ensure_ascii=False, indent=2)
        target.write("\n")
    os.chown(temporary, metadata.st_uid, metadata.st_gid)
    os.chmod(temporary, stat.S_IMODE(metadata.st_mode))
    os.replace(temporary, path)
finally:
    if os.path.exists(temporary):
        os.unlink(temporary)
PY
  chown "$owner" "$f"
  log "  fixed Claude local settings: $f 喵~"
}
fix_claude_local_settings

while IFS= read -r f; do
  owner=$(stat -c '%u:%g' "$f")
  sed -i "s|$OLD_HOME|$NEW_HOME|g" "$f"
  chown "$owner" "$f"
  log "  fixed: $f"
done < <(grep -rl "$OLD_HOME" "$NEW_HOME/.dsh/.agent-presets" 2>/dev/null || true)

# 8) Claude Code project dir rename + memory symlink
PHASE=claude-projects
CP="$NEW_HOME/.claude/projects"
if [ -d "$CP/-home-$OLD" ] && [ ! -e "$CP/-home-$NEW" ]; then
  mv "$CP/-home-$OLD" "$CP/-home-$NEW"
  log "  claude project dir: -home-$OLD -> -home-$NEW"
fi
mkdir -p "$CP/-home-$NEW"
chown "$UID_NEW:$GID_NEW" "$CP/-home-$NEW"
ln -sfn "$NEW_HOME/.agents/memory" "$CP/-home-$NEW/memory"
chown -h "$UID_NEW:$GID_NEW" "$CP/-home-$NEW/memory" 2>/dev/null || true

# OpenCode 会话目录属于数据库元数据,登录后用 OpenCode `session.move` API 迁移喵~
# 不要直接编辑 SQLite 数据库喵~
PHASE=post-check
if [ -e "$OLD_HOME" ]; then
  log "WARNING: $OLD_HOME exists again; an old-HOME session may have recreated it 喵~"
  log "Do not delete it without a fresh manifest and checking its contents 喵~"
else
  log "old home path is absent 喵~"
fi
PHASE=complete
log "done. Reboot now, then log in as $NEW 喵~"
log "full migration log: $LOG_FILE 喵~"
log "After login, run .agents/config/migrate-opencode-sessions.sh as $NEW to re-home V2 session metadata 喵~"
