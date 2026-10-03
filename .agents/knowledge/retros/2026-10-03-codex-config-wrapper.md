---
date: 2026-10-03
module: home/reiky/dev/codex.nix, lib/agents.nix(只读引用), ~/.claude.json(运行时), ~/WorkSpace/tools/obsidian-mcp-server(删除)
tags: [codex, mcp, reiky-nixpkgs, hm, wrapper, wire-api, cleanup]
related: [2026-10-03-mcp-obsidian-gc-fix]
---

# 复盘: 清理上一轮遗留 (Codex 双配置 / 废弃 flake / Claude 死历史)

## 背景

`2026-10-03-mcp-obsidian-gc-fix` 留下的三个遗留, 本次一并处理喵~

## 遗留 1: Codex 双配置 (HM 写了个没人读的文件)

### 症状 / 根因
- `codex.nix` 把 provider 写进 `~/.config/codex/config.toml`喵~ 但 Codex CLI(0.133.0)
  实际读取并**自行改写** `~/.codex/config.toml`(`codex --help`: "-c ... loaded from
  `~/.codex/config.toml`")喵~ 于是 HM 那份是**死文件**, Codex 一直没认证
  (`codex doctor`: "no Codex credentials were found")喵~
- 实验证实 Codex 会原子改写 `$CODEX_HOME/config.toml`(追加 `[projects]` /
  `[notice]` / `[mcp_servers]`), 所以**不能用 `home.file` 软链托管** —— 只读的 store
  目标会被 Codex 的原子替换成真实文件, 造成 HM 漂移喵~
- 另: HM 旧配置写的是 `wire_api = "chat"`, 而 **Codex >= 0.133 移除了 `chat`**,
  只接受 `responses`(否则 "failed to load configuration")喵~ 即便路径对也会被拒喵~

### 解法
- `codex.nix` 删除软的 `home.file.".config/codex/config.toml"`, 改为安装一个
  **包装脚本** `codex`, 用 `-c` 在运行时注入 provider(值仍来自 `agents.nix` 注册表)喵~
  这样声明式, 又不与 Codex 自管的 config.toml 冲突喵~
- `wire_api` 用 `responses`(实测 DeepSeek 的 `https://api.deepseek.com/v1`
  在 responses 模式下可用)喵~
- 验证: `codex --version` OK;`codex doctor` 显示
  `provider deepseek` / `provider auth env var DEEPSEEK_API_KEY_REIKY (present)` /
  `✓ reachability`;`codex exec 'reply with exactly: WRAPPER_OK'` 返回
  `WRAPPER_OK`(端到端)喵~
- HM 已自动清掉死软链 `~/.config/codex/`喵~

## 遗留 2: 废弃的家目录开发 flake

- `~/WorkSpace/tools/obsidian-mcp-server` 与 Reiky-nixpkgs `pkgs/obsidian-mcp-server`
  的源码逐字节一致, 已被声明式包取代喵~ 删除该目录(51M)喵~
- `~/WorkSpace/tools/` 现为空目录(保留)喵~

## 遗留 3: Claude `~/.claude.json` 死历史

- 删除 6 条指向旧用户名的 `projects` 键(`/home/Reiky-REI/...`, 这些目录已不存在)喵~
  备份到 `~/.claude/backups/.claude.json.bak-*`;校验 JSON 合法且 `Reiky-REI` 归零喵~
- 剩余 projects: `/etc/nixos`、`/home/reiky`(有效)喵~

## 踩坑 / 要点

1. **Codex 配置是"可变运行态"**, 不是纯声明式配置喵~ 需要 `home.file` 之外的机制
   (包装脚本 `-c` 覆盖是函数式且无副作用的选择)喵~
2. **Codex `-c` 的值为 TOML**, 且必须放在子命令**之前**(它是全局选项)喵~
3. **版本漂移**: Codex 0.133 移除 `wire_api="chat"`, 升级时这类契约变化要留意喵~
4. 处理"双配置"要先确认真实读取路径(`--help`/`doctor`), 别凭 XDG 直觉喵~

## 验证

- `readlink -f $(command -v codex)` → 包装脚本;`~/.config/codex` 不存在喵~
- `codex doctor` → provider deepseek, auth 由 provider 提供, 端点可达喵~
- `codex mcp list` → kb enabled(路径已修正)喵~
- `codex exec` → `WRAPPER_OK`喵~
