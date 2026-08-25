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

## 自动索引维护（事件驱动钩子）
- systemd 用户级 `kb-corpus.path` 监听全部根的语料树（章程文件 + knowledge/** 与 memory/** 目录树），编辑落盘即触发 `kb-corpus.service`（warm-all.sh 全量 sweep，签名短路只重建真正变更的根）喵~
- 新项目初始化 .agents 后重跑一次 `gen-kb-paths.sh` 刷新监视清单；没刷新也不影响使用（首次检索懒建兜底）喵~
- 手动全量预热：直接运行 `warm-all.sh`；运行日志 `~/.cache/kb-warm.log` 喵~

## 启动与触发链路（运维视角）

开机自启链路喵~
1. NixOS 启动 → **linger** 让 Reiky-REI 的 systemd 用户管理器免登录自启（`loginctl show-user Reiky-REI -p Linger` = yes）喵~
2. 用户管理器达 default.target → `kb-corpus.path`（已 enable）挂载全部监视路径，进入监听态喵~
3. 各根索引缓存持久化于 `<根>/.agents/tools/kb-mcp/index/index.json`，重启不丢；钩子若缺席，客户端首调的懒重建兜底仍生效喵~

编辑触发链路喵~

    任意 AI / 编辑器写入 .md
      -> 内核 inotify 事件(毫秒级)
      -> kb-corpus.path 触发 kb-corpus.service (TriggerLimit 20s/5 合并编辑风暴)
      -> warm-all.sh: flock 防重入 -> 全根签名比对(纯 stat, 不碰模型)
      -> 变更根全量重嵌入写缓存; 未变根 SAME 秒跳过
      -> 日志 ~/.cache/kb-warm.log; 失败由下次事件或手动 warm-all.sh 自愈

新增项目后：`bin/init-agents <dir>` 初始化，再跑一次 `gen-kb-paths.sh` 把新根纳入监视清单喵~
