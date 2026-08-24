---
id: 2026-08-24-kb-mcp-semantic-search
date: 2026-08-24
module: ".agents/tools/kb-mcp, modules/services/llama-cpp.nix"
tags: [kb-mcp, mcp, embedding, reranker, llama-cpp, systemd-resume]
severity: high
status: done
related: [".agents/knowledge/retros/2026-08-23-agents-system-overhaul.md"]
---

# 知识库语义检索 MCP(kb-mcp)落地 + 断电续命队列 + Qwen3-8B 下线

## 背景与目标
用户要求把知识库用本地 embedding+reranker 封装成 MCP 给所有 agents 做辅助决策, 且不破坏既有体系喵~ 同时裁定 Qwen3-8B 太蠢直接下线, 并要求进程被杀后能无人干预续命喵~ 

## 选型调研结论
mcp-server-qdrant/basic-memory/mcp-memory-service/chroma-mcp 均需引入自带嵌入栈与存储, 无法复用宿主机已在运行的 Qwen3 双端点(:8081/:8082), 中文语料适配差 —— 结论: 自研薄 MCP 层(~300行纯标准库), 复用现有推理, 零新增依赖喵~ 

## 架构与实现
- 语料: AGENTS/SKILLS/knowledge/** 共 469 chunks(frontmatter 感知分块, 1024 维)喵~ 
- 管线: 余弦 top48 + BM25(CJK bigram) top24 → 融合分(0.72/0.28) → rerank 精排 → top-k喵~ 
- 缓存: index.json(b64 float32 + size/mtime 签名, 自动增量失效)喵~ 
- 注册: opencode.json(项目级)+.mcp.json(Claude)+~/.codex/config.toml 三端齐挂, AGENTS.md 写入强制条款与 grep 分工喵~ 
- 续命: agent-resume.path/timer/linger + 任务队列(done/failed/log/state.json), 成功失败均消息板通报喵~ 

## 踩坑与修复
1. embed 归一化写成列表除法(list/float) → TypeError; 改逐元素除喵~ 
2. 候选池按 chunk 下标升序截断 → 最新文档(下标最大)永远进不了精排; 改融合分排序取 top12喵~ 
3. rerank HTTP500 "input too large, physical batch size 512": rerank 编码受 **--ubatch-size** 限制, 仅调 --batch-size 无效; 两实例分别补 1024/2048喵~ 
4. systemd user .path 因队列快速进出触发过频撞 StartLimit 熔断(unit-start-limit-hit); path/service 配 StartLimitIntervalSec=0/放宽 + reset-failed 修复喵~ 
5. nixos-rebuild switch exit4: dsh-fence.service 引用不存在的 tailscale.service(他人工作流遗留, 已派单)喵~ 

## 验证
- 冒烟: initialize/tools/list/tools/call 全通; 「沙箱无权限根因」「dialogue.sh 元数据 bug」两条查询正确文档均列第 1 位喵~ 
- rerank 异常时自动回退混合分排序并标注, 工具不整体报错喵~ 
- 续命队列: 成功路径(done+marker)、失败重试路径(RETRY→FAILED)实测通过喵~ 
- build+switch 通过, chat 实例永久下线(systemd not-found), embed/rerank 健康 200喵~ 

## 遗留
- dsh-fence tailscale 依赖修复 → OpenCode(消息板派单)喵~ 
- MCP 注册需各 agent 重启会话才加载; 下次会话起生效喵~ 
