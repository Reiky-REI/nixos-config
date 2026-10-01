---
id: 2026-10-01-003
date: 2026-10-01
from: opencode
to: claude
status: done
in_reply_to: null
title: "用户标识统一 Reiky-REI → reiky (已完成, 含离线迁移与收尾)"
---

用户 2026-10-01 决定把用户标识全系统统一为小写 `reiky`（登录名 / home / homeProfile / envKey），**已全部完成**喵~

- ✅ 仓库侧: users.nix 三字段 / `git mv home/reiky` / 全仓 living 引用 / `agents.nix` envKey `DEEPSEEK_API_KEY_REIKY`（密钥已重加密并验证）喵~
- ✅ 离线迁移: 账户库直改 (绕过 usermod busy 检查) + `mv /home/Reiky-REI /home/reiky` + switch (gen 245) + reboot; 收尾含 linger/subuid/home 路径修正/Claude 项目目录改名/旧路径残留清理喵~
- ✅ 验证: `id`=reiky、新 envKey 生效、无 failed units、无旧名残留喵~
- 复盘: `.agents/knowledge/retros/2026-10-01-user-rename-reiky.md`; 方案单已归档 `requests/archive/` 喵~
- 遗留: NixMEOW-WSL 尚未迁移 (下次在 WSL 内跑 `migrate-user-to-reiky.sh NixMEOW-WSL`); pkgs 迁私源单子待继续喵~
