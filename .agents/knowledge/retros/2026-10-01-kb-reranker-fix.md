---
date: 2026-10-01
module: .agents/tools/kb-mcp/server.py, modules/services/llama-cpp.nix, .agents/knowledge/known-issues.md
tags: [kb-mcp, reranker, qwen3-vl, gguf, llama-cpp, embedding, cls-head, quantize]
layer: services
severity: high
related:
  - 2026-08-24-kb-mcp-semantic-search.md (kb-mcp 初建)
  - 2026-08-31-kb-model-docs-2b.md (数据事故后重部署 2B 模型)
  - ../known-issues.md (kb-mcp reranker 打分退化)
experience:
  - "Qwen3-VL-Reranker-2B 是生成式模型, /v1/rerank 需要 GGUF 自带 cls.output.weight + pooling=RANK, 社区转换版(e-2x 垃圾分)一律不可用"
  - "官方 convert_hf_to_gguf.py 会在 README 命中 '# qwen3-vl-reranker' 时自动补分类头; HF 的 additional_chat_templates/*.jinja 会覆盖 tokenizer.chat_templates 数组, 转换前需移走"
  - "VL reranker 的官方模板无 <think> 尾巴且指令是 candidates; 套用文本版模板会让分数区分度变差 (0.56/0.30 vs 0.54/0.07)"
  - "判据: 正确 reranker 对 relevant 给 ~0.5+, irrelevant ~0.0x; 若全为 1e-2x 且启动有 'pooling_type [-1]' 警告 = 坏转换"
  - "NixOS 上 pip 的 torch 会因 dlopen 找不到 libstdc++/libz 失败; 需在 LD_LIBRARY_PATH 里补 gcc-lib 和 zlib, 或走 nixPackages"
---

# 复盘: 修复 kb-mcp reranker 语义精排 (Qwen3-VL-Reranker-2B 重转)

## 起因
用户问「MCP 的 reranker 返回和 grep 有什么不同」, 实测时发现 `/v1/rerank` 对所有文档返回 `1e-28~1e-36` 级分数、排序近似随机, 也就是 kb-mcp 的「精排」其实一直是噪声喵~

## 取证
- 直接打端点: query「如何烹饪红烧肉」+ [红烧肉做法, 天气, NixOS 配置] → NixOS 排第一, 红烧肉排最后 (完全错); 分数 `e-28`。
- 官方对照: `ggml-org/Qwen3-Reranker-0.6B-Q8_0-GGUF` 同样输入 → `0.9986 / 1.7e-5` (正确)。说明端点没问题, 是模型 GGUF 的问题。
- 启动日志: `model default pooling_type is [-1], but [4] was specified` → 当前 GGUF 不带 reranker 元数据。
- HF config: `Qwen3-VL-Reranker-2B` 架构是 `Qwen3VLForConditionalGeneration`(生成式), `/v1/rerank` 的 rank 分支需要 `cls.output.weight`。
- 结论: 8-31 数据事故后重新部署的 GGUF 是社区坏转换 (llama.cpp#16407), 缺分类头。

## 修复
1. 用官方 `convert_hf_to_gguf.py`(llama-cpp-9190 自带, `conversion/qwen.py`)重转 Qwen/Qwen3-VL-Reranker-2B:
   - `_is_qwen3_reranker` 命中 README 的 `# qwen3-vl-reranker`; `Qwen3VLTextModel` 继承 `Qwen3Model`, 从 `embed_tokens` 取 `yes`(9693)/`no`(2152) 两行生成 `cls.output.weight`, 写 `pooling_type=RANK` + `classifier.output_labels`。
   - 命令: `python convert_hf_to_gguf.py --outtype q8_0 --outfile out.gguf <hf-model 目录>` (生成式直转 q8_0, 免去 f16 中间件省磁盘)。
2. 坑① 模板数组被覆盖: HF 的 `additional_chat_templates/reranker.jinja` 让 gguf-py 把 `tokenizer.chat_templates` 写成 `["reranker"]`, 而 llama-server `format_prompt_rerank` 只找名为 `rerank` 的模板, 找不到就退化成 query+SEP+doc → 转换前把 `additional_chat_templates/` 移走, 数组恢复成 `["rerank"]`。
3. 坑② VL 模板: 转换器给所有 Qwen3 reranker 套同一个文本模板(结尾带 `<think>\n\n</think>\n\n`, 指令写 "passages"); VL 官方模板(其 `reranker.jinja`)无 think、指令是 "candidates"。实测文本模板 0.56/0.30, 换成 VL 模板后 0.54/0.07, 区分度显著变好。
4. 部署: 留证 (`~/.local/state/delete-manifests/20261001-reranker-model-replacement.txt`) 后, 旧 GGUF 改名 `.broken-orig-20261001` 保留, 新 GGUF 覆盖部署, 重启 `llama-cpp-reranker`。
5. 防御: `server.py` 增加退化分数检测(若 top 分 < 1e-6 → 回退混合召回收排序 + 标注), 并把 `[0.000]` 改成科学计数显示。

## 验证
- 端点: 红烧肉 `0.538 / 0.073 / 0.069` (中文), 英文 `0.614 / 0.107`; 启动无 `pooling_type [-1]` 警告。
- `kb_search` 端到端: 「睡太久黑屏」首条 = known-issues 黑屏 `0.728`; 「未验证改动怎么存」首条 = validation-gated feedback `0.719`, 次条 Stash 示例 `0.599`。

## 环境坑
- NixOS 上 pip 装的 torch 因 dlopen 找不到 `libstdc++.so.6` / `libz.so.1` 无法 import; 需 `LD_LIBRARY_PATH` 补 `gcc-15.2.0-lib/lib` 和 `zlib-1.3.2/lib`(nix-ld 只覆盖可执行文件, 不覆盖 dlopen)。
- 转换环境: venv + `pip install torch --index-url .../cpu numpy transformers sentencepiece safetensors pyyaml`; 源码用 llama.cpp `b9190` tarball(与运行中的 llama-cpp-9190 同版)。

## 遗留 / 建议
- 旧坏 GGUF 备份 (`.broken-orig-20261001`, 1.8G) 验证通过后可删(留证同 manifest)。
- 转换 recipe 已写入本复盘与 `known-issues.md`; 若升级 Qwen3-VL-Reranker 或 llama.cpp, 需重新按此重转并跑「红烧肉」对照。
- `server.py` 的退化回退在新会话生效 (MCP 进程重启后)。
