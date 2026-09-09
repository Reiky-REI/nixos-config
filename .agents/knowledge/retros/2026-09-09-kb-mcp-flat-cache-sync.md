---
date: 2026-09-09
module: .agents/tools/kb-mcp/server.py
tags: [kb-mcp, mcp, cache-invalidation, bug-fix, embedding, swap, 索引]
layer: common
severity: medium
related:
  - ../retros/2026-08-24-kb-mcp-semantic-search.md (kb-mcp 初建)
  - ../retros/2026-08-31-kb-model-docs-2b.md (换 2B 模型后同因内存态未生效的教训)
  - ../../known-issues.md (kb-mcp array index out of range 章节)
experience:
  - "缓存失效三要素(chunks/bm25/_flat)必须同生共死: ingest() 换了 chunks 却留旧 _flat 向量数组, 是教科书级 cache-invalidation bug —— 改一组派生状态时, 把全部派生物放同一个 update 点喵~"
  - "报错 `array index out of range`(array 而非 list) 即可定位到 array.array 下标越界: cosine_top 用新 chunk 数迭代旧 vec 数组喵~ 报错关键词区分容器类型能大幅缩短定位喵~"
  - "离线回归测试法: monkeypatch embed/rerank 成确定性假实现 + KB_CACHE_DIR 指临时目录, 秒级复现'搜索→re-ingest→再搜索'崩溃路径, 不占用 llama 服务也不碰真实缓存喵~"
  - "opencode 的 stdio MCP 不会在会话中途重启: 杀 kb-mcp 进程后当前会话 kb 工具消失属预期, 修复对新会话生效; 验证可另开 server.py 走 stdio 直发 JSON-RPC 完成端到端检查喵~"
  - "kb_search 超时的另一半根因是内存压力(waydroid 常驻 + embedding 批处理把 embedding 服务挤进 5.1G swap), 修 bug 前先看 free -h 与 journalctl -u llama-cpp-embedding, swap 重负载下重启 llama 服务是标准动作喵~"
---

# 复盘: kb-mcp "array index out of range" — ingest 后 _flat 缓存不同步

## 现象喵~

本会话给 known-issues 加坑7 + 新增复盘 + gen-index 重写索引后, `kb_search` 先一次超时(MCP -32001), 随后报 `ERROR: array index out of range` 喵~

## 排查喵~

1. `kb_stats`: corpus=605 chunks, dim=2048, index_built 12:31:35, embed/rerank 均 ok(200) —— 后端健康, 指向服务端代码问题喵~
2. 读 `server.py`: `kb_search` 第 271 行 `STATE.get("_flat") or load_flat()` 拿到**旧向量数组**; `cosine_top` 第 253 行 `for r in range(len(ch))` 按**新 chunks 数**迭代 → `vec[off+j]` 越界, array.array 抛 "array index out of range"(list 才报 list index)喵~
3. 根因: `ingest()` 只 `STATE.update(chunks=chunks, dim=dim)`, 没同步 `STATE["_flat"]` 喵~

## 修复喵~

```python
# ingest(): norm_rows 后
STATE["_flat"] = vec
# load_cache(): norm_rows 后同样补
STATE["_flat"] = vec
```

回归测试(离线假 embed/rerank + 临时 KB_CACHE_DIR): 首搜 → 触碰源文件改 sig → 再搜 —— 旧代码在此必崩, 新代码 re-ingest 后正常喵~

## 生效与验证喵~

- `systemctl restart llama-cpp-embedding llama-cpp-reranker` 清 swap 挤压(重启后内存 11G 用→6G 用)喵~
- 杀掉两个旧 kb-mcp server.py 进程; 本会话 kb 工具消失(opencode 不中途重启 MCP, 属预期)喵~
- stdio 直发 JSON-RPC 对真实语料端到端搜索成功, 召回结果正确命中 waydroid/白闪相关复盘喵~

## 遗留喵~

- 其余打开 kb 的会话需重开才能拿到修复; 下次会话起 kb_search 恢复正常喵~
