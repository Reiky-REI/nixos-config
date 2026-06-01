---
date: 2026-06-01
module: home/Reiky-REI/apps/openclaw.nix
tags: [openclaw, ai-assistant, nix-openclaw, garnix-cache, pnpm]
layer: home
severity: medium
related:
  - ../known-issues.md
  - ../../requests/pending/2026-06-01-openclaw.md
experience:
  - "nix-openclaw overlay 用系统 nixpkgs 构建，Garnix 缓存用 nix-openclaw 自己的 nixpkgs，hash 不同。解决：显式指定 package = openclaw.packages.${system}.default"
  - "pnpm 在国内通过代理下载 npm 包很慢，会超时。Garnix 缓存可以绕过"
  - "bundledPlugins 的 peekaboo 在 Linux 不支持（linux = false），只能在 macOS 用"
  - "weixin runtime plugin 在当前 nix-openclaw 版本不被支持（不在 supportedIds 列表）"
  - "memory.backend = qmd 需要 qmd 包，Linux 上可能不可用"
---

## OpenClaw 集成复盘

### 任务
按 `requests/pending/2026-06-01-openclaw.md` 委托，将 OpenClaw 个人 AI 助手网关集成到 NixOS 配置中。

### 实际改动
1. `flake.nix` — 新增 `openclaw` input（不 follow 本系统 nixpkgs）
2. `flake.nix` — 新增 `openclaw.overlays.default` 到 nixpkgs overlays
3. `home/Reiky-REI/apps/openclaw.nix` — 新建，配置 OpenClaw
4. `home/Reiky-REI/apps/default.nix` — 追加导入

### API Key 方案变更
- 原方案：新建专用 age 文件放 ANTHROPIC_API_KEY
- 实际方案：走 cc-switch 本地代理（127.0.0.1:15721），复用现有 provider
- 原因：用户已有 cc-switch 管理的 provider（当前 xiaomi/deepseek），不需要单独 key

### 踩坑记录

#### 1. Garnix 缓存 hash 不匹配（最大坑）
- **现象**：build 一直在下载 pnpm 依赖，超时失败
- **原因**：nix-openclaw overlay 用系统 nixpkgs（25.11）构建，但 Garnix 缓存用 nix-openclaw 自己的 nixpkgs（nixos-unstable）。不同 nixpkgs → 不同 nodejs/pnpm 版本 → 不同 derivation hash → 缓存 miss
- **解决**：显式指定 `package = openclaw.packages.${system}.default`，直接引用 nix-openclaw flake 输出（走 Garnix 缓存）

#### 2. bundledPlugins 的 peekaboo 不支持 Linux
- **现象**：`openclawPlugin is null` 错误
- **原因**：plugin-catalog.nix 中 peekaboo 的 `linux = false`
- **解决**：移除 peekaboo

#### 3. weixin runtime plugin 不支持
- **现象**：`runtimePlugins contains unsupported ids: weixin`
- **原因**：nix-openclaw 当前版本不支持 weixin 作为 runtime plugin
- **解决**：移除 runtimePlugins = ["weixin"]

#### 4. qmd memory backend 需要 qmd 包
- **现象**：`memory.backend = "qmd" requires a qmd package`
- **原因**：qmd 包在当前 nixpkgs 下不可用
- **解决**：改为 `memory.backend = "builtin"`

#### 5. nixpkgs.follows 导致问题
- **现象**：Garnix 缓存完全失效
- **原因**：follow 本系统 nixpkgs 后，所有依赖版本都变了
- **解决**：去掉 `inputs.nixpkgs.follows = "nixpkgs"`，让 nix-openclaw 用自己的 nixpkgs

### 最终配置
- Gateway 模式：local，认证 token
- 模型提供者：anthropic → cc-switch 代理（127.0.0.1:15721）
- Bundled plugins：summarize（启用）
- Memory：builtin（非 qmd）
- 未启用：weixin channel、peekaboo、qmd

### 后续可做
- 等 nix-openclaw 支持 weixin runtime plugin 后启用
- 等 qmd 在 Linux 可用后切换 memory backend
- 启动 OpenClaw 前需运行 `cc-switch proxy enable`
