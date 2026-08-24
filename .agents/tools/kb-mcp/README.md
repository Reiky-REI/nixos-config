# kb-mcp -- NixMEOW 知识库语义检索 MCP server

纯 Python 标准库实现(零第三方依赖), 调用本机 llama.cpp 推理端点:
- Embedding: Qwen3-Embedding-0.6B @ :8081 (/v1/embeddings, 1024维)
- Reranker:  Qwen3-Reranker-0.6B   @ :8082 (/v1/rerank)

语料: .agents/{AGENTS.md,SKILLS.md,knowledge/**} frontmatter 感知分块。
管线: 余弦 top48 + BM25 top24 -> 融合分(0.72/0.28) -> reranker 精排 top12 -> 返回 top-k。
索引缓存: index/index.json (源文件 size+mtime 签名, 变更自动重建; 已 gitignore)。

## 工具
- kb_search {query, k?, module?, tag?} -- 语义检索(排障/查决策/写复盘前必用)
- kb_ingest {} -- 手动强制重建索引
- kb_stats {}  -- 语料与端点健康

## 注册方式(各 agent 客户端)
- OpenCode 项目级 opencode.json:
  "mcp": { "kb": { "type": "local", "command": ["<python3>", "<server.py>"], "enabled": true } }
- Claude Code 项目根 .mcp.json:
  { "mcpServers": { "kb": { "command": "<python3>", "args": ["<server.py>"] } } }
- Codex ~/.codex/config.toml:
  [mcp_servers.kb]
  command = "<python3>"
  args = ["<server.py>"]

本仓库三处均已注册; 若会话内不可用, 重启 agent 会话后生效。
