---
title: "用户身份全系统统一为 reiky (登录名 / home / homeProfile / envKey)"
requester: "NixMEOW/opencode"
date: "2026-10-01"
request_id: "2026-10-01-user-rename-to-reiky"
priority: "medium"
status: "approved"
---

## 申请内容

把用户相关标识全部统一为小写 `reiky`（stable user ID 已是 `reiky`，但登录名 / home 目录 / homeProfile 仍是 `Reiky-REI`，仓库目录 `home/Reiky-REI/` 违反「小写 + 连字符」命名规范）。

| 项 | 现状 | 目标 | 说明 |
|----|------|------|------|
| user ID | `reiky` | `reiky` | 不变 |
| 登录名 | `Reiky-REI` | `reiky` | 系统账户改名 |
| home 目录 | `/home/Reiky-REI` | `/home/reiky` | 真实目录迁移 |
| homeProfile | `Reiky-REI` | `reiky` | 仓库目录同步 `git mv` |
| 密钥 | `ai-api-key-reiky` | 不变 | 已统一 |
| 密钥内 envKey | `DEEPSEEK_API_KEY_REIKY_REI` / `AGNES_API_KEY_REIKY_REI` | `DEEPSEEK_API_KEY_REIKY` / `AGNES_API_KEY_REIKY` | 重新加密 |
| GitHub handle | `Reiky-REI` | 不变 | 外部账号，非本机标识 |

## 为什么需要

用户 2026-10-01 指示：仓库命名规范（小写 + 连字符）与用户标识不一致；在「仓库侧改小写 / 连系统账户一起改」中选择了**完整迁移**方向，避免留下两套形态。

## 具体方案

### Phase 1 — 仓库侧（agent 执行，本分支 `chore/user-rename-to-reiky`）

- `users.nix`：`username` / `homeDirectory` / `homeProfile` → `reiky`（`githubHandle` 保持）
- `git mv home/Reiky-REI home/reiky`
- 全仓 living 引用更新：README、docs/、decisions/、known-issues、AGENTS、kb-mcp、config 脚本、pending request 等
  （历史文档 `retros/`、`dialogue/`、`requests/archive/`、`docs/archive/` 保持原样）
- `agents.nix` `envKey` + 密钥内容变量改名（解密 → sed → `age -e -R` 重加密 → 解密比对验证；备份在 `~/.local/state/secret-backups/`）
- 新增迁移脚本 `.agents/config/migrate-user-to-reiky.sh`
- 验证：`nixos-rebuild build` + `just check-docs`

### Phase 2 — NixMEOW 离线迁移（用户执行，约 5 分钟）

```text
1. 登出图形会话（回到 ly 登录界面）
2. Ctrl+Alt+F3 切 TTY，用 Reiky-REI 登录
3. sudo -i
4. bash /etc/nixos/.agents/config/migrate-user-to-reiky.sh
5. reboot → 用 reiky 登录
```

脚本内容：停 `nas-mount` 并卸载 `~/nas`（CIFS 挂载点必须先卸）→ 直改账户库 `/etc/passwd|shadow|group|gshadow` + `mv` 家目录（**绕过 `usermod` 的 busy 检查**：linger 的 `systemd --user` 与用户服务会让 usermod 拒绝，见处理记录）→ subuid/subgid 迁移 → linger 迁移 → `nixos-rebuild switch` → home 内非声明式文件绝对路径修正（保留属主）→ Claude 项目目录改名 + memory 链接重建。

### Phase 3 — NixMEOW-WSL（之后有空再做）

同一脚本可复用：`... migrate-user-to-reiky.sh NixMEOW-WSL`（先退出嵌套 niri）。WSL 内 home 同样位于 `/home/Reiky-REI`，需同步骤迁移；`wsl.defaultUser` 自动跟随。

### Phase 4 — NixMEOW-CTR

容器镜像重建即生效，无持久 home、无离线步骤。

## 预期影响

- 所有 systemd 服务 `User = username`、agenix owner / identityPaths、NTFS `uid=` 挂载、tmpfiles `win` 链接：均由 `users.nix` 字段驱动，**自动跟随**
- podman 已有容器：uid 不变 + subuid 范围保留 → 不受影响
- 手工点仅限 home 内非声明式文件（`.claude/settings.json` hook 路径、`.dsh/storages/workspace.json`、`.dsh/.agent-presets/*`、Claude 项目目录名）— 由脚本第 6/7 步处理
- `/etc/nixos` 属主 uid 1002 不变，文件权限不受影响

## 验证方式

- `id` / `whoami` = `reiky`；`echo $HOME` = `/home/reiky`
- `ls /run/agenix/ai-api-key-reiky` 可读；`echo ${DEEPSEEK_API_KEY_REIKY:+set}`（新终端）
- `systemctl status nas-mount kb-mcp* --user` / `agent-resume` 正常；`loginctl show-user reiky -p Linger` = yes
- 图形登录、壁纸、fcitx5、Codex（新 envKey）正常
- `nix eval .#nixosConfigurations.NixMEOW.config.home-manager.users.reiky` 可求值

## 回滚

- switch 失败：旧 generation 仍可引导，但账户已改名 → 不回滚配置，修复后前向重跑（脚本幂等）
- 密钥异常：从 `~/.local/state/secret-backups/` 恢复旧 `.age` 并回退 `agents.nix`

## 处理记录

| 日期 | 操作 | 说明 |
|------|------|------|
| 2026-10-01 | 提交 | 用户选定「连系统账户一起改」方向 → `approved` |
| 2026-10-01 | 执行(repo) | Phase 1 完成：users.nix / git mv / 全仓引用 / envKey 重加密 / 迁移脚本 |
| 2026-10-01 | 修正 | `usermod` 被 linger 服务占用拒绝（process 1415 = `systemd --user`）→ 脚本改为直改账户库 + `mv`（uid 不变，幂等可重跑） |
| | 执行(build) | ⬜ 等待 Phase 2 离线迁移 |
| | 复盘 | `retros/{日期}-{主题}.md` |
| | 归档 | `archive/` |

## 关联复盘
<!-- 执行后填写 -->
- `{复盘文件路径}`
