---
date: 2026-09-20
module: .agents/tools/kb-mcp/server.py
tags: [kb-mcp, mcp, 缓存, 快照, ingest]
layer: common
severity: medium
related:
  - 2026-09-09-kb-mcp-flat-cache-sync.md (同类"缓存不同步"家族: _flat 向量数组)
  - 2026-08-24-kb-mcp-semantic-search.md (kb-mcp 初版设计)
experience:
  - "长驻进程里的模块级快照(SOURCES)会让 ingest/ensure_fresh 永远看不到新文件 — 文件发现必须放在扫描函数内部每次重算"
  - "验证索引类修复要绕开长驻 server: 用 importlib 在独立 python 进程里调 scan_sources()/ingest(), 否则测的是旧代码"
  - "kb_ingest 显示'已重建索引'但 chunk 数不变 = 强信号, 说明扫描源集合没变, 优先查快照而非embedding"
---

# kb-mcp 看不到新增复盘 — SOURCES 快照修复

## 现象
写并提交了 `retros/2026-09-19-dsh-fence-dead-dep.md`, 跑 `kb_ingest` 返回"已重建索引: 655 chunks"（与修复前同数）, 且 `kb_search` 只命中 8/16 的旧复盘喵~

## 根因
`server.py` 模块级 `SOURCES = _collect_sources()` 在进程导入时求值一次, `scan_sources()` 直接遍历这个快照喵~ 长驻 MCP server 进程启动后新增的 .md 永远进不了扫描集合, 所以 ingest 重建的仍是旧语料, chunk 数当然不变喵~
验证: 独立进程 import 后发现 SOURCES 已含新文件（82 条 / retros 72 篇 = 磁盘数）, 证明快照本身正确、只是运行的进程过期喵~

## 修复
`scan_sources()` 内改为每次调用 `_collect_sources()` 重新发现文件喵~ 独立进程实测: 655 → 659 chunks, 新复盘已纳入, 并立即用新代码重建 cache（7.7MB, 27.5s）喵~

## 遗留
运行中的 MCP server 仍是旧代码, 需**重启客户端会话**才生效（新会话加载新代码后 `ensure_fresh` 自会处理增量）喵~
