---
date: 2026-06-06
module: modules/desktop/fcitx5/fcitx5.nix, modules/services/ai/
tags: [rime, llm, qwen3, ollama, rollback, fcitx5]
layer: services
severity: medium
related:
  - ../../known-issues.md
experience:
  - "RIME 会拦截符号输入（如$$），导致 Obsidian LaTeX 渲染失效"
  - "ollama-cuda 在 nixpkgs 中需要从源码编译 CUDA，耗时 30+ 分钟"
  - "Qwen3 的 thinking 模式在 Ollama OpenAI API 中无法禁用"
  - "Ollama systemd 服务需要 HOME 环境变量"
  - "fcitx5 用 pinyin 时不会拦截 $$ 符号，但 RIME 会"
  - "RIME Lua 插件需要 fcitx5-rime addon，不能用 pinyin addon"
---

## RIME + Qwen3 智能输入法尝试 — 回滚

### 背景
尝试为 RIME 输入法添加本地 LLM 驱动的智能输入功能。

### 最终结果：❌ 回滚

### 失败原因

#### 1. Obsidian LaTeX `$$` 失效
- RIME 接管输入后，`$` 字符被 RIME 拦截用于符号处理
- Obsidian 无法收到 `$$` 来触发 LaTeX 渲染
- 原因：RIME 的 `ascii_composer` 和符号处理机制与 Obsidian 冲突

#### 2. AI 建议不显示
- RIME Lua 插件配置正确，但 Lua filter 未被 RIME 执行
- 可能是 fcitx5-rime 版本或 Lua 环境问题
- 需要更深入的调试

#### 3. 编译时间过长
- `ollama-cuda` 需要从源码编译 CUDA，耗时 30+ 分钟
- CPU 版 ollama 秒装，但性能不足

### 踩坑记录

| 坑 | 原因 | 解决方案 |
|---|------|---------|
| `$$` 失效 | RIME 拦截符号输入 | 回滚到 pinyin |
| AI 不显示 | Lua filter 未执行 | 需进一步调试 |
| CUDA 编译慢 | nixpkgs 无预编译 | 用 ollama (CPU) |
| HOME 未定义 | Ollama systemd 配置 | 添加 HOME 环境变量 |

### 经验教训
1. **输入法切换影响符号输入** — RIME 和 pinyin 对符号的处理不同
2. **NixOS CUDA 编译很慢** — 需要预编译或用 CPU 版本
3. **小模型中文能力有限** — 0.6B 模型在某些任务上表现不稳定

### 回滚操作
- 切回 main 分支
- 删除 feature branch `ai/rime-qwen3-input-method`
- 删除 Ollama 服务和模型
- 清理 RIME Lua 配置
- 恢复 fcitx5 为 pinyin 输入法
