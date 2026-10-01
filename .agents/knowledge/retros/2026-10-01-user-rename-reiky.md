---
date: 2026-10-01
module: users.nix, lib/mk-host.nix, home/reiky/**, secrets/ai-api-key-reiky.age, .agents/config/migrate-user-to-reiky.sh
tags: [user-identity, rename, agenix, linger, subuid, migration]
layer: common
severity: medium
related:
  - ../requests/archive/2026-10-01-user-identity-rename-to-reiky.md (方案单)
  - ../dialogue/2026-10-01-003-opencode-to-claude-user-rename-pending.md (跨 AI 交接)
experience:
  - "usermod 在任何该用户进程存在时拒绝 (currently used by process N); linger 的 systemd --user 与常驻服务必然命中 → 改名要么先停掉全部用户进程 (含登录会话), 要么直改 /etc/passwd|shadow|group|gshadow + mv 家目录 (uid 不变, 幂等可重跑)"
  - "家目录内有挂载点 (NAS CIFS ~/nas) 时无法整体 mv → 必须先 systemctl stop nas-mount + umount"
  - "迁移窗口内仍以旧 HOME 运行的会话/服务会在旧路径重建家目录 (本次 151M: Chrome 临时 profile 75M / clash-verge 运行时 33M / opencode 状态 7.8M) → 迁移后应尽快让所有会话重新登录 (或直接重启), 旧路径按删除清单清理"
  - "per-user 状态按名字存储, 要随改名一起迁移: /var/lib/systemd/linger/<name>、/etc/subuid|subgid、/etc/profiles/per-user/<name>、~/.claude/projects/-home-<path> 目录、非声明式配置里的绝对路径"
  - "NixOS 激活会给新用户名重新分配 subuid 范围 (本次 231072 → 100000); 已有 rootless podman 容器映射会受影响, 需留意"
  - "仓库侧用 homeProfile 字段与登录名解耦; 本次按用户决定直接统一为 reiky (小写+连字符), GitHub handle 保持 Reiky-REI"
---

# 用户标识全系统统一 (Reiky-REI → reiky) 复盘

## 背景与需求

用户要求全系统命名统一: 仓库目录 `home/Reiky-REI/` 违反「小写+连字符」规范喵~ 在「仓库侧改小写 / 连系统账户一起改」两个方向中, 用户选择了**完整迁移**: 登录名、家目录、homeProfile、密钥 envKey 全部统一为 `reiky`喵~

## 执行

1. **仓库侧 (Phase 1)**: `users.nix` 三字段改 `reiky`; `git mv home/Reiky-REI home/reiky`; 全仓 living 引用更新 (README/docs/decisions/known-issues/kb-mcp/config 脚本); `agents.nix` envKey `DEEPSEEK_API_KEY_REIKY` / `AGNES_API_KEY_REIKY` (密钥解密→改名→重加密→解密比对验证, 备份在 `~/.local/state/secret-backups/`); 新增 `.agents/config/migrate-user-to-reiky.sh`喵~
2. **离线迁移 (Phase 2)**: 账户库直改 + `mv /home/Reiky-REI /home/reiky` + `nixos-rebuild switch` (gen 245) + reboot喵~
3. **收尾**: linger 迁移 (`enable-linger reiky`)、subuid/subgid 核对、home 内非声明式路径修正 (`.claude/settings.json`、`.dsh/storages`、agent-presets、Claude 项目目录 `-home-Reiky-REI*` → `-home-reiky*` + memory 链接)、旧路径残留 151M 清理 (删除清单 `delete-manifest-reiky-home-leftover-20261001-123451.txt`)喵~

## 验证

- `id` = uid 1002(reiky), `HOME=/home/reiky`; `/etc/passwd|group|subuid` 无旧名残留喵~
- 新 envKey 生效: 交互 zsh 中 `DEEPSEEK_API_KEY_REIKY` / `AGNES_API_KEY_REIKY` / `NIX_ACCESS_TOKEN` 均已设置; `/run/agenix/ai-api-key-reiky` 可读喵~
- 无 failed units (system/user); `agent-resume.path/timer`、`kb-corpus.path`、`kbdlight-sync`、`nas-mount`、`dsh-fence`、`netease-cdn-bypass` 全部 active喵~
- 仓库: NixMEOW build / WSL+CTR eval / check-docs 全过喵~

## 坑与经验

见 frontmatter `experience` 列表喵~ 最关键的三个: usermod busy 检查 (直改账户库绕过)、CIFS 挂载点阻塞 mv、旧 HOME 会话重建旧路径残留喵~

## 遗留

- **NixMEOW-WSL**: 尚未执行迁移 (WSL 内 home 仍是 `/home/Reiky-REI`); 下次在 WSL 内跑 `migrate-user-to-reiky.sh NixMEOW-WSL` 即可喵~
- **NixMEOW-CTR**: 镜像重建即生效, 无离线步骤喵~
- pkgs 迁私源单子 (`2026-10-01-pkgs-to-private-source`) 待继续喵~
