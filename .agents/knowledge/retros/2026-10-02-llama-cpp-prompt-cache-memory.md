---
date: 2026-10-02
module: modules/services/llama-cpp.nix
tags: [llama-cpp, prompt-cache, memory, embedding, reranker, kb-mcp, oom]
layer: services
severity: medium
related:
  - 2026-09-09-disk-cleanup-llama-gpu.md (embedding/reranker 从 CPU 切 GPU)
  - 2026-08-24-kb-mcp-semantic-search.md (kb-mcp 初建)
experience:
  - "llama-server 默认开启 prompt KV 缓存且 --cache-ram 默认 8192 MiB; 对无状态的 /v1/embeddings 请求毫无复用价值, 却会把每个请求的 prompt 存进缓存并常驻, 单进程 RSS 顶满 8G"
  - "判据: journal 出现 `cache state: N prompts, 8xxx MiB (limits: 8192.000 MiB)` + `saving idle slot to prompt cache`, 且进程 Pss_Anon 达数 GB 而 GPU 显存正常"
  - "修复: embedding/reranker 服务 ExecStart 加 `--no-cache-prompt --cache-ram 0` (0=disable); 缓存是主机匿名内存, 与显存无关"
  - "常驻 systemd 服务的内存不会随调用方(opencode/claude)退出而释放; 排查'用过 X 之后内存不降'先看是不是 system 服务常驻"
  - "nixos-rebuild switch 风险有边界: 先 dry-activate 看会重启哪些单元, 只重启普通服务(未触及 polkit/nix-daemon/dbus/display-manager)时 compositor 安全"
---

# 复盘: llama-server prompt cache 常驻 8G 内存 (kb 用后不释放)

## 起因
用户报告「每次 opencode 用过 kb 之后, 哪怕 opencode 关了 RAM 占用还是这么高」喵~ 实测系统 14G 只剩 ~950Mi 可用, 内存压力 full avg10 4.2%, swap 已用 3.3G。

## 取证
- `ps aux --sort=-%mem`: 第一名 `llama-server` PID 1583 **RSS 8.4G**, 属于 **system 服务** `llama-cpp-embedding.service`, PPid=1、开机自启; 与 opencode 无父子关系。
- opencode 侧完全正常: `opencode serve` 270M、`kb-mcp/server.py` 13M。**关闭 opencode 当然不释放**, 因为服务从来不归它管。
- `smaps_rollup`: `Pss_Anon 7.7G` / private dirty 7.9G, 全是**不可回收的主机匿名内存**; `nvidia-smi` 显示模型在显存 2966 MiB, 与这 8G 无关。
- journal 实锤:
  `srv update: - cache state: 501 prompts, 8189.135 MiB (limits: 8192.000 MiB, 4096 tokens, 74882 est)`
  以及大量 `slot slot_save_an: saving idle slot to prompt cache`。
- 根因: `llama-server` 默认 `--cache-prompt` 开启, `--cache-ram` 默认 8192 MiB。kb 把语料分块(`server.py` `embed()` 每批 12 条)发给 `/v1/embeddings`, 每个请求的 prompt KV 被存进缓存且不主动释放, 累积到 8G 上限。embedding 是无状态单次前向, 缓存零收益。
- reranker 因 `--rerank` 模式不做 idle-slot 保存, RSS 仅 ~90M, 未受影响(但为对称仍加同样参数)。

## 修复
`modules/services/llama-cpp.nix`: embedding 与 reranker 的 `ExecStart` 各追加
```
--no-cache-prompt \
--cache-ram 0
```
`--cache-ram 0` = 禁用缓存上限; `--no-cache-prompt` = 关闭提示词缓存, 双保险。

顺带清理 chat 死代码: Qwen3-8B 模型文件早已删除、`chat.enable` 无任何 host 启用, 但模块里仍残留 `chat.enable` 选项、`llama-cpp-chat` 服务块与注释; 本次一并移除, 避免误导。

## 验证
- `nixos-rebuild build --flake .#NixMEOW` 通过; `dry-activate` 确认只重启 `llama-cpp-embedding` / `llama-cpp-reranker` 两个单元(未触及 polkit/dbus/nix-daemon)。
- switch 后: embedding cgroup `MemoryCurrent=1.79G`(peak 2.1G), RSS 626M; reranker RSS ~1.0G; `free` 可用 950Mi → **8.3G**。
- **压力复现**: 向 :8081 连发 600 条唯一嵌入请求(修复前足以填满缓存) → RSS 538M → **637M**, `VmHWM 2.1G`, journal 中 `cache state` / `saving idle slot` 行数为 **0**。
- 全链路: `kb_stats` → `embed ok(200) | rerank ok(200)`; `kb_search` 返回正常精排; reranker 直连测试相关文档 0.481 > 0.361 > 0.17。

## 遗留 / 建议
- chat 移除后 `services.llama-cpp` 仅剩 embedding + reranker 两个实例, 文档/注释已同步。
- 若未来再开其他 llama.cpp 常驻实例, 默认都应显式设 `--cache-ram`(生成式 chat 可保留缓存但建议限制上限, 避免同样顶满)。
- 排查同类问题口诀: 先 `ps --sort=-%mem` 认服务归属, 再 `smaps_rollup` 分匿名/文件, 再看 journal 找缓存/缓冲区增长证据。
