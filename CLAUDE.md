# NixMEOW — Claude Code 工作指南

本仓库由 **Claude Code** 和 **OpenCode** 共同维护。
共享约定统一放在 `.agents/` 目录下。开工前请先阅读：

- `config.nix` — 用户配置中心（username 等标识统一在此定义）
- `.agents/AGENTS.md` — 总指南 & 协作规则
- `.agents/SKILLS.md` — 技能索引 (按场景查找操作流程)
- `.agents/knowledge/INDEX.md` — 全部知识索引
- `.agents/knowledge/conventions.md` — 编码约定
- `.agents/knowledge/known-issues.md` — 已知问题 & 避坑
- `.agents/knowledge/architecture.md` — 仓库架构

> 以 `.agents/` 为准，不另设重复知识源。

## 配置自动生成

Claude Code 的项目设置由 Nix 驱动生成，与 OpenCode 的 `generate-opencode.sh` 对应：

```bash
just generate-claude    # 生成 .claude/settings.local.json
just generate-opencode  # 生成 opencode.json
just generate-all       # 全部生成
```

- 数据源：`lib/claude-config.nix`（定义权限、路径等）
- 生成脚本：`.agents/config/generate-claude.sh`
- 用户名等标识读取自 `config.nix`，修改后重新 `just generate-claude` 即可同步

## 开工流程

1. **读入口** — 先读 `.agents/AGENTS.md` `.agents/knowledge/INDEX.md` `.agents/knowledge/conventions.md`
2. **Plan mode** — 修改配置前先进入 Plan mode 设计方案
3. **查已知问题** — 遇到报错先查 `.agents/knowledge/known-issues.md`
4. **改完验证** — `nixos-rebuild build --flake /etc/nixos#NixMEOW`
5. **写复盘** — 配置变更完成后写复盘到 `.agents/knowledge/retros/`

## 与 OpenCode 的对齐规则

- 代码约定完全一致：以 `.agents/` 下的约定为准
- Git 工作流一致：feature branch → build 验证 → 提交 → 推送 → 复盘
- **Claude 特有**：利用 hooks 自动同步配置（pre-commit 触发 `just generate-claude`）
- **Claude 特有**：利用持久化记忆跨会话保持上下文
- 经验教训共享：发现的新坑同时更新到 `known-issues.md`

## 持久化记忆

Claude Code 的记忆系统位于 `/home/Reiky-REI/.claude/projects/-etc-nixos/memory/`，用于跨会话保留项目上下文。需要时直接存取。
