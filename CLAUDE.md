# NixMEOW — Claude Code 工作指南

本仓库由 **Claude Code** 和 **OpenCode** 共同维护。
共享约定统一放在 `.agents/` 下。

## ⚠️ 开机强制流程 — 每次会话先执行，不可跳过

全部读完再开工。边读边写总结到 memory，便于跨会话追溯。

1. **AGENTS.md** → `.agents/AGENTS.md` — 总纪律、协作规则、Git 工作流
2. **INDEX.md** → `.agents/knowledge/INDEX.md` — 知识索引 & 复盘清单
3. **conventions.md** → `.agents/knowledge/conventions.md` — 编码约定 & 分层规则
4. **known-issues.md** → `.agents/knowledge/known-issues.md` — 已知问题 & 避坑
5. **architecture.md** → `.agents/knowledge/architecture.md` — 仓库架构
6. **读近期复盘** → 扫 INDEX.md 中复盘列表，读最近 3-5 条了解当前状态
7. **读持久化记忆** → 读 `MEMORY.md`，加载上次会话记录的 user/project/feedback

按需加载（此时可根据已读的 INDEX.md 判断是否需要）：
- **查历史事故/既有决策/踩坑时** → MCP 工具 `kb_search`（语义检索, 强制场景见 .agents/AGENTS.md「知识库语义检索 MCP」章节）
- 遇到报错时查 known-issues.md
- 管理密钥时读 `secrets.md`
- 需要操作流程时读 `SKILLS.md` → 对应技能文件

> 等同于 OpenCode 的 `instructions: [AGENTS.md, INDEX.md, conventions.md]`。
> 不加载直接开工 → 不熟悉仓库 → 必然踩坑。

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

## 工作流

1. **Plan mode** — 修改配置前先进入 Plan mode 设计方案
2. **查已知问题** — 遇到报错先查 `.agents/knowledge/known-issues.md`
3. **改完验证** — `nixos-rebuild build --flake /etc/nixos#NixMEOW`
4. **写复盘** — 配置变更完成后写复盘到 `.agents/knowledge/retros/`

## 与 OpenCode 的对齐规则

- 代码约定完全一致：以 `.agents/` 下的约定为准
- Git 工作流一致：feature branch → build 验证 → 提交 → 推送 → 复盘
- **Claude 特有**：利用 hooks 自动同步配置（pre-commit 触发 `just generate-claude`）
- **Claude 特有**：利用持久化记忆跨会话保持上下文
- 经验教训共享：发现的新坑同时更新到 `known-issues.md`

## 持久化记忆

Claude Code 的记忆系统位于 `/home/Reiky-REI/.claude/projects/-etc-nixos/memory/`，用于跨会话保留项目上下文。

**每次会话必须执行：**
- **开工** → 先读 `MEMORY.md` 回顾上次上下文
- **收工** → 写关键进展、用户偏好、踩坑经验到 memory（不写复盘替代 memory，两者并存）

memory 存什么：无法从代码/git 推导的信息（用户偏好、决策原因、反馈、项目状态）。
复盘归复盘（`.agents/knowledge/retros/`），memory 归 memory，不互相替代。
