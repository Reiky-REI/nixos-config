# NixMEOW — Codex 项目指令

本仓库由 **OpenCode**、**Claude Code** 和 **Codex** 共同维护喵~

Codex 开工前**必须**先读取以下文档, 按顺序加载, 全部读完再动手:

1. `.agents/AGENTS.md` — 总纪律、协作规则、Git 工作流、喵~ 规则
2. `.agents/knowledge/INDEX.md` — 知识索引 & 复盘清单
3. `.agents/knowledge/conventions.md` — 编码约定 & 分层规则
4. `.agents/knowledge/known-issues.md` — 已知问题 & 避坑
5. `.agents/knowledge/architecture.md` — 仓库架构
6. 扫 `.agents/knowledge/retros/` 近期复盘 3-5 条

## 快速命令

- dry-run: `sudo .agents/config/rebuild.sh`
- build: `sudo .agents/config/rebuild.sh build` (推荐)
- switch: `sudo .agents/config/rebuild.sh switch` (⚠️ NVIDIA PRIME 崩溃风险, 不要主动执行)
- 后台编译: `sudo systemd-run --unit=nix-rebuild ...`

## 要点速览

- **绝不直接在 main 上改** — 每个任务开一个 feature branch
- **改完先 build** — `nixos-rebuild build --flake /etc/nixos#NixMEOW` 验证
- **写复盘** — 非平凡变更完成写复盘到 `.agents/knowledge/retros/`
- **排障先问知识库** — 用 MCP 工具 `kb_search` 语义检索 retros/decisions/known-issues, 场景与用法见 `.agents/AGENTS.md`
- **喵~ 规则** — 输出自然语言时用"喵~ "替代标点
- **NixOS 选项坑** — swaync/swayidle/polkit-gnome 是 HM 选项; Niri 用 `switch-to-named-submap`; nvidia-offload 调用独显

> 详细规则以 `.agents/AGENTS.md` 为准, 本文件只是 Codex 的入口索引。
