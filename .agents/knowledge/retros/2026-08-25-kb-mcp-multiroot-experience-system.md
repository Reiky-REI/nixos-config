---
id: kb-mcp-multiroot-experience-system
date: 2026-08-25
module: .agents/tools/kb-mcp
tags: [kb-mcp, mcp, experience-system, workspace]
severity: low
status: resolved
related: [~/.agents/AGENTS.md, ~/WorkSpace/.agents/, ~/.config/opencode/opencode.jsonc, ~/.claude.json, ~/.codex/config.toml]
---

# kb-mcp 上下文多根改造 + 全目录经验体系推广喵~

## 背景与目标
用户要求把经验体系从 /etc/nixos 推广到 ~ 与 ~/WorkSpace, 且原则上每个目录都要有自己的经验体系, 并接入 MCP 工作流与沟通机制喵~

## 方案
server.py 升级为**上下文感知多根**: KB_ROOT env > cwd 向上最近有效 `.agents` > 回落 /etc/nixos; 语料发现泛化为顶层章程文件 + knowledge/** + memory/**喵~ 三客户端改为**全局注册**(opencode 全局 jsonc / claude 用户级 .claude.json / codex 已有全局条目), 一次注册全目录生效, 项目零配置喵~

## 落地内容
- /etc/nixos 语料 483 -> 503 chunks(新增 INDEX 等); 家目录新语料 204 chunks; WorkSpace 12 chunks; 10 个子项目各 5 chunks, 全部预热完成喵~
- WorkSpace 散件归整: 根散落复盘补 frontmatter 归位 `.agents/knowledge/retros/`; NOTE-reranker 提炼为正式复盘(家目录)后原件平移归档 artifacts/config-snippets/; 过期 llama-cpp.reranked.nix 同归档喵~
- 章程可见性: ~/AGENTS.md 与 ~/WorkSpace/AGENTS.md 符号链接到各自 .agents/AGENTS.md(codex 向上查找即命中); 新增 ~/WorkSpace/CLAUDE.md 指引; 两处 AGENTS.md 增补 kb 强制使用条款与沟通机制(消息板/HANDOFF/MEMORY)喵~
- 7 个活跃项目用既有 `~/WorkSpace/bin/init-agents` 初始化轻量 .agents(blueprint-vm/DeepSec/dsh-routing-suite/dsh-https-proxy/nxwatch/dsh-deepsec-guard/mcp-agents-bridge); 各仓库工作区脏, 遵守纪律不代提交喵~

## 验证
- stdio 直连: 13 根 kb_stats 全部 root 解析正确、embed/rerank ok喵~
- 检索质量: 家目录查"reranker 分数随机" -> 目标复盘 top1 score 0.999喵~
- 实弹: opencode 于 ~/WorkSpace 调 kb_kb_stats 返回 root=WorkSpace|12 chunks; claude 于 ~ 经用户级注册调 mcp__kb__kb_stats 返回 root=/home/Reiky-REI|204 chunks(num_turns=2 证实真实调用)喵~

## 已知边界
- codex 运行时仍缺 API 凭据(401), 配置本身验证通过, 凭据就绪即可用喵~
- blueprint-vm/DeepSec/dsh-routing-suite 的 .agents/ 为未跟踪脚手架, 待仓库所有者顺手提交喵~

## 后续升级：事件驱动索引维护（同日追加）
两分钟轮询定时器方案被用户否决，改为 **systemd.path 事件钩子**喵~ `gen-kb-paths.sh` 枚举全部根的章程文件与 knowledge/**、memory/** 目录树，生成单个 `kb-corpus.path`（52 条监视路径），编辑落盘即触发 `kb-corpus.service` → `warm-all.sh` 全量 sweep，签名短路只重建变更根喵~ 实弹验证：touch 一个知识文件后 **1 秒内**自动触发，12 个未变根秒级跳过，变更根精确重建仅 38s 喵~
