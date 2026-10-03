---
date: 2026-10-03
module: home/reiky/dev/default.nix, home/reiky/tools/opencode-settings.json, flake.lock, Reiky-nixpkgs:pkgs/obsidian-mcp-server
tags: [mcp, obsidian, opencode, claude-code, codex, gc, nix, reiky-nixpkgs, rename]
related: [2026-10-01-username-migration]
---

# 复盘: 修复 obsidian-vault MCP "找不到服务器" (GC 断链 + 改名僵尸路径)

## 症状

- OpenCode: `opencode mcp list` → `obsidian-vault  failed: NotFound: ChildProcess.spawn
  (/home/reiky/WorkSpace/tools/obsidian-mcp-server/result/bin/obsidian-mcp-server)`喵~
  (kb / tolaria 正常)
- Claude Code: `claude mcp list` → `kb` 与 `obsidian-vault` 均 `✘ Failed to connect`喵~
- Codex: `~/.codex/config.toml` 的 `kb` 指向旧用户名路径 (未直接报错,但 spawn 必失败)喵~

## 根因 (两个独立问题叠加)

1. **GC 断链**:`obsidian-mcp-server` 原本在家目录 `~/WorkSpace/tools/` 里用本地 flake
   `nix build` 出 `result` 软链喵~ 家目录的 `result` **不是持久 GC root**,一次
   `nix-collect-garbage` 就把 store 路径回收,`result` 变成悬空链接喵~ 又因其 flake 的
   `inputs.nixpkgs` 锁成了 `/nix/store/...-source` 绝对路径 (该 path 也被 GC),
   连重建都无法直接重放喵~
2. **改名僵尸路径**:2026-10-01 用户名 `Reiky-REI` → `reiky` 后,Claude `~/.claude.json`
   的 kb/obsidian-vault、Codex `~/.codex/config.toml` 的 kb 仍是旧绝对路径喵~
   (`/etc/profiles/per-user/Reiky-REI/...`、`/home/Reiky-REI/...`)

## 改动

### Reiky-nixpkgs (main `3e1570b`)
- 新增 `pkgs/obsidian-mcp-server/`(收编 TypeScript 源码 src/ + package.json +
  package-lock.json + tsconfig.json)喵~
- `buildNpmPackage` + `npmDepsHash`(沿用原值即通过),`installPhase` 输出 `dist` +
  `node_modules` 并生成 `bin/obsidian-mcp-server` 包装喵~
- flake.nix overlay + packages 注册喵~
- 验证: `nix build .#obsidian-mcp-server` 成功;MCP `initialize` 握手返回
  `serverInfo: obsidian-vault 0.1.0`喵~

### /etc/nixos (`feat/mcp-obsidian-fix`)
- `home/reiky/dev/default.nix`: `home.packages += obsidian-mcp-server`(落 profile,GC 安全)喵~
- `home/reiky/tools/opencode-settings.json`: obsidian-vault command 改为
  `/etc/profiles/per-user/reiky/bin/obsidian-mcp-server`喵~
- `flake.lock`: Reiky-nixpkgs bump 到 `3e1570b`喵~
- `nixos-rebuild build` 通过 → `switch` 后 `result/etc/profiles/per-user/reiky/bin/obsidian-mcp-server`
  就位喵~

### 其他 AI (非声明式,手工校正)
- Claude Code: 用 `claude mcp remove/add -s user` 重加 `kb` 与 `obsidian-vault`
  (修正 python 路径 + obsidian command/env)喵~
- Codex: `~/.codex/config.toml` 把 `Reiky-REI` → `reiky`(kb command + projects key)喵~

## 验证 (全绿)

```
OpenCode: ✓ kb  ✓ obsidian-vault  ✓ tolaria
Claude:   ✔ kb  ✔ obsidian-vault  ✔ tolaria
Codex:    kb  enabled  (/etc/profiles/per-user/reiky/bin/python3 ...)
```

opencode 工具目录里已出现 `obsidian-vault`(10 个工具)喵~ 说明运行时真的连上了喵~

## 踩坑 / 要点

- **家目录 flake 的 `result` 不是 GC root**喵~ 需要长期被按路径调用的二进制一律进
  Reiky-nixpkgs + home.packages喵~ 已写入 `known-issues.md`喵~
- **flake 别锁 store 绝对路径当 nixpkgs input**喵~ 会被 GC 且不可复现喵~
- 改名遗留的绝对路径分布在**每个 AI 客户端各自的配置里**(`.claude.json` / `codex
  config.toml` / `opencode-settings.json`),迁移时容易漏喵~ 以后 rename 要全量 grep喵~

## 遗留 / 边界

- 家目录 `~/WorkSpace/tools/obsidian-mcp-server/` 的开发 flake 已废弃但保留(悬空
  `result` 未删);新路径以 Reiky-nixpkgs 为准喵~
- Codex 存在**两份配置**:HM 生成的 `~/.config/codex/config.toml`(写 model/provider)
  与实际被读取的 `~/.codex/config.toml`(手维护,含 kb MCP)喵~ 二者用途不一致,
  待后续统一(本次不动,避免覆盖手维护状态)喵~
- `~/.claude.json` 里 6 处 `projects./home/Reiky-REI/...` 是死历史(新路径已不存在),
  与 MCP 无关,保留喵~
- Gemini / Cursor 仅引用正常的 tolaria,无需改动喵~
