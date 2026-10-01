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
#     5. reboot  ->  log in as reiky
#   NixMEOW-WSL:
#     sudo -i bash /etc/nixos/.agents/config/migrate-user-to-reiky.sh NixMEOW-WSL
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

log() { printf '\033[1;34m[migrate]\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m[migrate:error]\033[0m %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" = 0 ] || die "must run as root (sudo -i)"

# 0) repo config must already use the new name
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
  if mountpoint -q "$OLD_HOME/nas"; then
    log "stopping nas-mount and unmounting $OLD_HOME/nas"
    systemctl stop nas-mount.service 2>/dev/null || true
    umount "$OLD_HOME/nas" || die "failed to unmount NAS - check manually and rerun"
  fi

  # 2) move the home directory (same fs -> atomic rename)
  if [ "$HOME_MOVED" = 0 ]; then
    [ -d "$OLD_HOME" ] || die "$OLD_HOME not found"
    [ ! -e "$NEW_HOME" ] || die "$NEW_HOME already exists - aborting"
    log "mv $OLD_HOME -> $NEW_HOME"
    mv "$OLD_HOME" "$NEW_HOME"
  else
    log "home dir already moved - continuing"
  fi

  # 3) rename in account databases (backup first; uid unchanged)
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
for f in /etc/subuid /etc/subgid; do
  [ -f "$f" ] || continue
  if ! grep -q "^$NEW:" "$f" && grep -q "^$OLD:" "$f"; then
    sed -i "s/^$OLD:/$NEW:/" "$f"
  else
    sed -i "/^$OLD:/d" "$f"
  fi
done

# 5) linger (systemd user manager without login) moves to the new name
loginctl enable-linger "$NEW" 2>/dev/null || true
rm -f "/var/lib/systemd/linger/$OLD"

# 6) activate the new configuration (login/home/homeProfile/envKey all updated)
log "nixos-rebuild switch --flake /etc/nixos#$HOST"
if ! nixos-rebuild switch --flake "/etc/nixos#$HOST"; then
  die "switch failed - account renamed but config not activated; fix and rerun (idempotent)"
fi

# 7) fix absolute paths in non-declarative files inside the home dir
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
fix_file "$NEW_HOME/.dsh/storages/workspace.json"
while IFS= read -r f; do
  owner=$(stat -c '%u:%g' "$f")
  sed -i "s|$OLD_HOME|$NEW_HOME|g" "$f"
  chown "$owner" "$f"
  log "  fixed: $f"
done < <(grep -rl "$OLD_HOME" "$NEW_HOME/.dsh/.agent-presets" 2>/dev/null || true)

# 8) Claude Code project dir rename + memory symlink
CP="$NEW_HOME/.claude/projects"
if [ -d "$CP/-home-$OLD" ] && [ ! -e "$CP/-home-$NEW" ]; then
  mv "$CP/-home-$OLD" "$CP/-home-$NEW"
  log "  claude project dir: -home-$OLD -> -home-$NEW"
fi
mkdir -p "$CP/-home-$NEW"
chown "$UID_NEW:$GID_NEW" "$CP/-home-$NEW"
ln -sfn "$NEW_HOME/.agents/memory" "$CP/-home-$NEW/memory"
chown -h "$UID_NEW:$GID_NEW" "$CP/-home-$NEW/memory" 2>/dev/null || true

log "done. Please reboot, then log in as $NEW"
