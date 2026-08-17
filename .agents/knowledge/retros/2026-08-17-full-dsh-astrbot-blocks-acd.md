---
date: 2026-08-17
module: modules/services/llama-cpp.nix, modules/services/default.nix, ~/WorkSpace/bin/, ~/.dsh/.agent-presets/nixos-guard/
tags: [llama-cpp, qwen, embedding, astrabot, dsh, mcp, agents, lsp]
layer: services
severity: medium
related:
  - ../../known-issues.md
  - ../../../docs/HANDOFF.md
experience:
  - "nixpkgs 26.05 把官方 llama-cpp 模块列为默认模块,自定义同名模块必须用 disabledModules = [ \"services/misc/llama-cpp.nix\" ] 替换。"
  - "dsh-fence 沙箱对 /etc/nixos 和 home 只读(EROFS),文件工具和 bash 都写不了;借道用户开的 root opencode serve(sudo)HTTP API 执行系统级变更。"
  - "DSH 沙箱进程带 NoNewPrivs:1 + Seccomp,内核级禁 setuid,沙箱内 sudo 永远不可用;root 操作只能走沙箱外的通道(如用户 tmux 里的 sudo opencode)。"
  - "opencode debug lsp 在 dsh-fence 内失败根因:它硬写 ~/.local/share/opencode/log/opencode.log + LSP server 二进制在 /etc/profiles/per-user/<user>/bin;wrapper 需重定向 XDG + 补 PATH。"
  - "AstrBot 4.27.3 / DSH(dsh-mcp-client)/ opencode 1.18 都是 MCP 客户端,没有原生 server;标准互调需要自建轻量 MCP server 或连 opencode serve。"
---

# 复盘: 完全体四件套 — 块 A 本地 Qwen + 块 C/D 经验体系与 LSP 共享

## 背景

按 HANDOFF-2026-08-17 推进完全体四件套喵~ 用户拍板: 8B 聊天 + 0.6B embedding 走 hf-mirror, 授权夜间 switch + 全面检查, 并在 tmux 开了 sudo opencode serve(9502)做 root 通道喵~

## 完成内容

### 块 A: 本地 Qwen(配置 + 模型已就绪, 待 build/switch)
1. 下载 Qwen3-8B-Q4_K_M.gguf(5.03G)+ Qwen3-Embedding-0.6B-Q8_0.gguf(639M)到 ~/WorkSpace/models/llama-cpp/, GGUF 魔数验证通过喵~
2. 重写 llama-cpp.nix 为自定义双实例 systemd 服务(chat 8080 + embedding 8081), User=Reiky-REI 直读 home 模型喵~
3. 关键坑: 官方 llama-cpp 模块在 26.05 是默认模块, 重复声明 services.llama-cpp 选项冲突 → disabledModules 替换喵~
4. 准备 AstrBot 注入脚本 add-local-qwen-provider.sh(provider_sources 加 chat + embedding)喵~

### 块 C: 每文件夹经验体系
1. .agents-templates/AGENTS.md 轻量模板 + bin/init-agents 脚本(测试通过)喵~
2. ~/WorkSpace/.agents 已初始化并补全 WorkSpace 特有约定喵~
3. AstrBot /dsh 链路自动继承 DSH preset rule 8(读 .agents)喵~

### 块 D: LSP 共享(修通)
1. 根因: opencode 硬写 ~/.local/share/opencode/log/opencode.log(HOME 只读) + LSP server 二进制不在 dsh-fence PATH喵~
2. 修复: opencode-lsp wrapper 重定向 XDG 到 ~/WorkSpace/.xdg + PATH 补 /etc/profiles/per-user/Reiky-REI/bin喵~
3. 验证: diagnostics 返回 {file: []}, document-symbols 与 root 通道行为一致喵~
4. DSH preset rule 8 更新为使用 wrapper 喵~

### 块 B: MCP 调研(设计稿, 待落地)
1. 三方能力矩阵确认: 都是 MCP 客户端喵~
2. 设计文档 HANDOFF-2026-08-17-mcp-design.md 给出 A/B/C 三档拓扑喵~

## 待办
- build 完成(首次编译 CUDA 全家桶, 较慢)→ git 提交 → switch → 全面检查
- AstrBot 注入本地 provider + 重启 astrabot + 端到端验证
- 块 B 拓扑落地(等用户拍板 A 还是 B)