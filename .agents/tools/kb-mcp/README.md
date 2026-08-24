# kb-mcp -- NixMEOW 知识库语义检索 MCP server

纯 Python 标准库实现(零第三方依赖), 调用本机 llama.cpp 推理端点:
- Embedding: Qwen3-Embedding-0.6B @ :8081 (/v1/embeddings, 1024维)
- Reranker:  Qwen3-Reranker-0.6B   @ :8082 (/v1/rerank)

## 上下文多根模式 (2026-08-25 起)

语料根按优先级解析, 让**每个目录拥有自己的经验体系**:

1. 环境变量 `KB_ROOT` (显式指定)
2. cwd 向上逐级寻找最近的有效 `.agents`(含 AGENTS.md 或 knowledge/)
3. 回落 `/etc/nixos` 系统库

收录顶层 AGENTS/SKILLS/MEMORY/CLAUDE.md + `knowledge/**` 与 `memory/**`
全部 md(frontmatter 感知分块)。每根独立索引缓存于 `<根>/.agents/tools/
kb-mcp/index/index.json`; 测试可用 `KB_CACHE_DIR` 重定向。

管线: 余弦 top48 + BM25 top24 -> 融合分(0.72/0.28) -> reranker 精排
top12 -> 返回 top-k。索引缓存按源文件 size+mtime 签名自动失效重建
(语料变更后首次检索约 2 分钟重建, 属正常)。

## 工具
- kb_search {query, k?, module?, tag?} -- 语义检索当前上下文知识库(排障/查决策/写复盘前必用)
- kb_ingest {} -- 手动强制重建索引
- kb_stats {}  -- 解析到的 root、语料与端点健康

## 注册(三客户端均已全局配置, 项目无需重复注册)
- OpenCode 全局 `~/.config/opencode/opencode.jsonc`: mcp.kb (local)
- Claude Code 用户级 `~/.claude.json` 顶层 mcpServers.kb
- Codex 全局 `~/.codex/config.toml`: [mcp_servers.kb]

会话内不可用时重启 agent 会话生效。
