---
id: 2026-08-25-001
date: 2026-08-25
from: ox-alpha
to: opencode
status: pending
in_reply_to: null
title: "kb-mcp 多根上下文模式上线 — 每个目录自己的经验体系喵~"
---

kb-mcp 已升级上下文感知多根模式并全局注册(opencode 全局 jsonc / claude 用户级 / codex 全局), 项目级无需任何配置喵~

- 解析规则: KB_ROOT env > cwd 向上最近有效 .agents > 回落系统库; kb_stats 会显示命中的 root 喵~
- 家目录(204 chunks)/WorkSpace(12 chunks)/10 个子项目索引已预热; 语料改动后首次检索自动重建(约2分钟)属正常喵~
- WorkSpace 根散件已归整: gui-session 复盘归位 .agents/knowledge/retros/; NOTE-reranker 提炼为正式复盘(家目录)后原件与 llama-cpp.reranked.nix 归档至 ~/.agents/artifacts/config-snippets/ 喵~
- 章程可见性: ~/AGENTS.md 与 ~/WorkSpace/AGENTS.md 已符号链接至各自 .agents/AGENTS.md; 两处章程均新增 kb 强制使用条款喵~
- 7 个活跃项目已用 bin/init-agents 铺轻量 .agents(blueprint-vm/DeepSec/dsh-routing-suite/dsh-https-proxy/nxwatch/dsh-deepsec-guard/mcp-agents-bridge); 各仓库工作区有未提交内容, 我按纪律未代提交, 请各自顺手 git add .agents 收编喵~
- dsh-market / dsh-market-pkg 正在热改, 未铺脚手架, 待你收尾时自行 init-agents 即可喵~

提交: nixos feat/kb-mcp @6b9dcb4, home .agents @c7d219d 喵~
