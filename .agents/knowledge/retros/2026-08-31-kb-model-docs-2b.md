---
date: 2026-08-31
module: .agents/tools/kb-mcp, .agents/AGENTS.md, known-issues.md, astrabot/data/cmd_config.json
tags: [kb-mcp, embedding, reranker, qwen3-vl-2b, 2048dim, docs-sync, disk-full]
layer: services
severity: medium
related:
  - 2026-08-24-kb-mcp-semantic-search.md (kb-mcp 初建时的 0.6B/1024 维基线)
  - 2026-08-31-data-loss-incident.md (模型丢失后重部署为 2B 的源头)
  - ../known-issues.md (rclone vfs 缓存吃满根分区)
experience:
  - "load_cache 只校验语料签名不校验维度 → 换 embedding 模型后签名未变的根会静默沿用旧维缓存，向量错配全 0.000 分，必须手动删缓存强制重建"
  - "rclone --vfs-cache-mode full 的 /tmp/rclone 缓存可无声涨到 30G+，先 fsync 后 find -delete 即可回收（有清单留证）"
  - "模型名在文档与配置里有多重写法（0.6b/Qwen3-Embedding/纯 grep 单词会漏），先枚举全部形态再扫描"
  - "delete 留证模板：manifest 文件 + sha256 + size + 路径存 /root/evidence/"
---

# 复盘: KB 模型文档同步至 Qwen3-VL-2B + 索引 2048 维全量重建

## 背景
用户要求把所有文档从 0.6B 表述更新为实际已部署的 Qwen3-VL-Embedding-2B / Qwen3-VL-Reranker-2B 并重建索引。
调查发现: Nix 服务/GGUF/端点早已是 2B, 但文档 (README/AGENTS/known-issues) 与 AstrBot
`embedding_dimensions: 1024` 滞后; 更严重的是 12 个根的 KB 索引缓存还是 1024 维旧模型产物。

## 关键操作
1. 文档更新: kb-mcp/README.md 模型行+维度 1024→2048; AGENTS.md kb-mcp 段; known-issues.md
   两处 0.6b 条目标注重部署结果; AstrBot cmd_config.json embedding_dimensions 1024→2048 (备份 /root/evidence/)。
2. 磁盘 100% 满排障: /tmp/rclone VFS 缓存 33.8G (72h 策略未及时回收), journal vacuum 491M +
   留证后清理 vfs 缓存 → 可用 29G。
3. 索引重建: 发现 warm-all 签名短路会让未变更根保留旧维缓存 → 按铁律留证 (12 条 sha256+路径,
   /root/evidence/stale-1024-cache-manifest-20260831.txt) 后删除, sudo -u Reiky-REI 手动 warm-all。
4. 结果: 13 根全部 2048 维 (13:38-13:48); kb_search 分数恢复非零; rerank 端点实测正常。

## 遗留
- AstrBot 需 `systemctl restart astrabot` 才加载新维度配置 (未自动执行, 防中断在线会话)。
- 本会话 kb-mcp MCP 进程内存态仍是旧维, 会话重启后生效 (磁盘缓存已正确)。
- 两个 multiroot 候选: warm-all 的 find 只扫 WorkSpace maxdepth 3, 多层嵌套的 .agents 可能漏。
- 建议 (未实施): server.py load_cache 增加 dim 校验, 或缓存 schema 加 model 字段。
- git 未提交: archive-extract 分支有其他 AI 的 29 文件暂存改动, AGENTS.md/known-issues.md/.retros-index.md 暂存与本次编辑混叠, 按互查纪律移交由其收尾后一并提交 (本次改动文件见 module 字段)。

## 删除留证
- /tmp/rclone/vfs/*: 15065 条 manifest → /root/evidence/rclone-vfs-cache-manifest-20260831.txt
- 12 个 1024 维 index.json: /root/evidence/stale-1024-cache-manifest-20260831.txt
- cmd_config.json 修改前备份: /root/evidence/cmd_config.json.bak-20260831
