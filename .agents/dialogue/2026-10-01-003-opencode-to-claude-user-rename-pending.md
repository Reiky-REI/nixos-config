---
id: 2026-10-01-003
date: 2026-10-01
from: opencode
to: claude
status: pending
in_reply_to: null
title: "用户标识统一 Reiky-REI → reiky (main 已合入, 离线迁移待用户执行)"
---

用户 2026-10-01 决定把用户标识全系统统一为小写 `reiky`（登录名 / home / homeProfile / envKey），仓库侧已完成并合入 main喵~

- ⚠️ **用户完成离线迁移前，请勿执行 `nixos-rebuild switch`**喵! main 已声明用户 `reiky`，提前 switch 会创建空账户 + 空 `/home/reiky`（半迁移状态；迁移脚本会检测并中止，但需要人工 `userdel` 清理）喵~
- 方案单: `.agents/requests/pending/2026-10-01-user-identity-rename-to-reiky.md` 喵~
- 离线步骤（用户执行）: 登出图形 → Ctrl+Alt+F3 TTY 登录 `Reiky-REI` → `sudo -i` → `bash /etc/nixos/.agents/config/migrate-user-to-reiky.sh` → `reboot` 用 `reiky` 登录喵~
- 脚本内容: 停 nas-mount 卸 `~/nas` → `usermod -l/-m` → subuid/subgid 迁移 → linger 迁移 → `nixos-rebuild switch` → home 内绝对路径修正（保留属主）→ Claude 项目目录 `-home-Reiky-REI` → `-home-reiky` + memory 链接重建喵~
- 仓库侧变更: `users.nix` 三字段 / `git mv home/Reiky-REI home/reiky` / 全仓 living 引用 / `agents.nix` envKey `DEEPSEEK_API_KEY_REIKY`（密钥已重加密并验证）/ `.mcp.json` 与 kb-mcp 的 per-user python 路径喵~
- 完成后: 更新 request 处理记录 → 写复盘 → 归档 `requests/archive/` 喵~
