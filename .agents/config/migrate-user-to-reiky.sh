#!/usr/bin/env bash
# migrate-user-to-reiky.sh — 系统用户 Reiky-REI → reiky 完整迁移
#
# 背景与方案: .agents/requests/pending/2026-10-01-user-identity-rename-to-reiky.md
#
# 用法 (必须 root; 图形会话须已登出):
#   NixMEOW (主力机):
#     1. 登出图形会话 (回到 ly 登录界面)
#     2. Ctrl+Alt+F3 切到 TTY, 用 Reiky-REI 登录
#     3. sudo -i
#     4. bash /etc/nixos/.agents/config/migrate-user-to-reiky.sh
#     5. reboot  →  用 reiky 登录
#   NixMEOW-WSL (之后有空再做):
#     wsl -d NixMEOW-WSL -u Reiky-REI -- sudo -i bash /etc/nixos/.agents/config/migrate-user-to-reiky.sh NixMEOW-WSL
#
# 幂等: 已改名则跳过改名步骤, 直接进入激活/修复阶段; 中途失败可安全重跑。
set -euo pipefail

OLD=Reiky-REI
NEW=reiky
OLD_HOME=/home/$OLD
NEW_HOME=/home/$NEW
HOST="${1:-NixMEOW}"

log() { printf '\033[1;34m[migrate]\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m[migrate:错误]\033[0m %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" = 0 ] || die "必须 root 运行 (先 sudo -i)"

# 0) 前置: 仓库配置必须已更新为 reiky
grep -q "username = \"$NEW\"" /etc/nixos/users.nix || die "users.nix 尚未更新为 $NEW — 请先合并 chore/user-rename-to-reiky"

ALREADY=0
if id "$NEW" >/dev/null 2>&1 && [ -d "$NEW_HOME" ] && ! id "$OLD" >/dev/null 2>&1; then
  log "检测到账户已迁移 — 跳过改名, 直接进入激活/修复阶段"
  ALREADY=1
fi

if [ "$ALREADY" = 0 ]; then
  id "$OLD" >/dev/null 2>&1 || die "找不到用户 $OLD (是否已迁移? 检查 /etc/passwd)"
  id "$NEW" >/dev/null 2>&1 && die "用户 $NEW 已存在但 $OLD_HOME 仍在 — 半迁移状态, 请人工检查"
  [ -d "$OLD_HOME" ] || die "找不到 $OLD_HOME"
  [ ! -e "$NEW_HOME" ] || die "$NEW_HOME 已存在, 中止"

  pgrep -u "$OLD" -x niri >/dev/null 2>&1 && die "niri 图形会话仍在运行 — 请先登出图形会话"

  # 1) 卸载 home 内挂载 (NAS CIFS), 否则家目录无法整体 rename
  if mountpoint -q "$OLD_HOME/nas"; then
    log "停止 nas-mount 并卸载 $OLD_HOME/nas"
    systemctl stop nas-mount.service 2>/dev/null || true
    umount "$OLD_HOME/nas" || die "卸载 NAS 失败, 请手动检查后重跑"
  fi

  # 2) 账户改名 + 家目录迁移 (同文件系统 rename, 秒级)
  log "usermod -l $NEW -d $NEW_HOME -m $OLD"
  usermod -l "$NEW" -d "$NEW_HOME" -m "$OLD"

  # 3) podman subuid/subgid: 优先保留原范围 (已有容器映射不变)
  for f in /etc/subuid /etc/subgid; do
    [ -f "$f" ] || continue
    if ! grep -q "^$NEW:" "$f" && grep -q "^$OLD:" "$f"; then
      sed -i "s/^$OLD:/$NEW:/" "$f"
    else
      sed -i "/^$OLD:/d" "$f"
    fi
  done

  # 4) linger (systemd 用户管理器免登录自启) 迁移
  loginctl enable-linger "$NEW" 2>/dev/null || true
  rm -f "/var/lib/systemd/linger/$OLD"
fi

# 5) 切换到新配置 (登录名/home/homeProfile/envKey 均已更新)
log "nixos-rebuild switch --flake /etc/nixos#$HOST"
if ! nixos-rebuild switch --flake "/etc/nixos#$HOST"; then
  die "switch 失败 — 账户已改名但配置未激活; 修复后重跑本脚本 (幂等)"
fi

# 6) 修正 home 内非声明式文件的绝对路径 (root 执行, 注意保留属主)
UID_NEW=$(id -u "$NEW")
GID_NEW=$(id -g "$NEW")
log "修正 home 内绝对路径引用"
fix_file() {
  local f=$1 owner
  [ -f "$f" ] || return 0
  grep -q "$OLD_HOME" "$f" || return 0
  owner=$(stat -c '%u:%g' "$f")
  sed -i "s|$OLD_HOME|$NEW_HOME|g" "$f"
  chown "$owner" "$f"
  log "  修正: $f"
}
fix_file "$NEW_HOME/.claude/settings.json"
fix_file "$NEW_HOME/.dsh/storages/workspace.json"
while IFS= read -r f; do
  owner=$(stat -c '%u:%g' "$f")
  sed -i "s|$OLD_HOME|$NEW_HOME|g" "$f"
  chown "$owner" "$f"
  log "  修正: $f"
done < <(grep -rl "$OLD_HOME" "$NEW_HOME/.dsh/.agent-presets" 2>/dev/null || true)

# 7) Claude Code 项目目录改名 + memory 链接重建
CP="$NEW_HOME/.claude/projects"
if [ -d "$CP/-home-$OLD" ] && [ ! -e "$CP/-home-$NEW" ]; then
  mv "$CP/-home-$OLD" "$CP/-home-$NEW"
  log "  Claude 项目目录: -home-$OLD -> -home-$NEW"
fi
mkdir -p "$CP/-home-$NEW"
chown "$UID_NEW:$GID_NEW" "$CP/-home-$NEW"
ln -sfn "$NEW_HOME/.agents/memory" "$CP/-home-$NEW/memory"
chown -h "$UID_NEW:$GID_NEW" "$CP/-home-$NEW/memory" 2>/dev/null || true

log "✔ 迁移完成。请执行: reboot"
log "重启后用 $NEW 登录, 并按 request 文档的验证清单核对:"
log "  id; echo \$HOME; loginctl show-user $NEW -p Linger"
log "  ls /run/agenix/ | head; systemctl status kb-mcp* --user 2>/dev/null | head"
