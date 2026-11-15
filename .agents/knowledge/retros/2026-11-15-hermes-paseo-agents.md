---
date: 2026-11-15
module: flake.nix, home/reiky/tools/hermes.nix, home/reiky/tools/paseo.nix, modules/services/paseo.nix, lib/features.nix, machines.nix, lib/mk-host.nix, .agents/knowledge/multi-agent-coordination.md
tags: [hermes, paseo, multi-agent, worktree, flake, patchelf, uv2nix, systemd]
layer: services
severity: medium
related:
  - ../../known-issues.md (patchelf 0.19.2 补丁与 nixpkgs 回退; 家目录 flake result 不是 GC root)
  - ./2026-09-28-config-reproducibility-and-bot-retirement.md (退役 hermes-gateway 的旧记录)
experience:
  - "上游 flake 的 patch 依赖特定 patchelf 版本时, 必须跟着上游 flake.lock 的 nixpkgs 走, 不能 follows"
  - "GC 会清掉 nix run 的 flake result, 常驻工具必须声明式安装"
  - "多 agent 并行要的是 worktree 隔离 + 单点合并, 不是让多个 agent 同时改同一份工作区"
---

# Hermes Agent 重装 + Paseo 多 agent 编排层

## 背景

2026-09-09 曾用 `nix run github:NousResearch/hermes-agent -- setup` 装过 Hermes Agent 喵,
`~/.hermes` 里 config / skills / state.db 都还在喵~ 但 `nix run` 不产生 GC root 喵,
那个 nix store 路径后来被 GC 清掉, `hermes` 命令消失喵~ 9-28 退役 bot 栈时
`hermes-gateway.service` 也被一起禁用喵~

用户同时提出: 多 session / 多 agent 并行时互相打架喵,想引入 Paseo 解决喵~

## 改动

### Hermes Agent (声明式)

- `flake.nix`: 新增 `nixpkgs-hermes` 快照 + `hermes-agent` input 喵~
- `home/reiky/tools/hermes.nix`: 导入上游 `homeManagerModules.default` 喵,
  **只启用 `programs.hermes-agent`** (CLI; 不装 Electron Desktop) 喵~
- gateway 由本仓库自写 `systemd.user.services.hermes-agent` 常驻喵~
- 数据目录沿用 `~/.hermes`, 不迁移喵~

为什么不启用上游 `services.hermes-agent` 喵? 因为它会写 `.managed` 标记并导出
`HERMES_MANAGED`, 让 `hermes setup` / `hermes model` 全部拒改配置喵,
改个模型都要 rebuild 喵~ 这里换成自己声明 unit, 保留运行时改配置的自由喵~

### Paseo (编排层)

- `flake.nix`: 新增 `paseo` input, 锁 `v0.15.4` tag (main 上是 0.16.0-beta) 喵~
- `modules/services/paseo.nix`: `services.paseo` 以真实用户身份运行喵,
  只听 `127.0.0.1:6767`, relay 关闭 (远程走 tailscale 直连), 开 `features.webUi` 喵~
- 不装 Paseo Desktop (Electron), 用 daemon 自带 web UI (`http://localhost:6767`) + `paseo` CLI 喵~
- `lib/features.nix` + `machines.nix`: 新增 `paseo` 特性标签, 只在本机启用喵~
- `.agents/knowledge/multi-agent-coordination.md`: 协作规则 (见下) 喵~

## 为什么跳过 GUI (2026-11-15 用户决定)

第一次全量构建在 `hermes-agent-pnpm-deps` (Desktop 的 Electron 依赖树) 阶段
**ENOSPC** 挂掉喵, 当时磁盘只剩 1.5G 喵~ 用户随后明确"不要 GUI 也行"喵~
因此只留: Hermes CLI + gateway unit, Paseo daemon + web UI 喵~
省掉的构建量: hermes 的 pnpm/Electron/renderer、paseo 的 Expo/Electron 喵~

## 坑

## 坑 1: patchelf 补丁只适配 0.19.x, 而当前 nixpkgs 是 0.15.2

`follows = "nixpkgs"` 时构建失败喵: 上游 `nix/pm-packages.nix` 给 patchelf 打了
`fix-executable-header-load-overlap` 补丁 (写于 0.19.2) 喵, 而 26.05 stable /
`nixpkgs-715` / 2026-11 的 unstable **都是 patchelf 0.15.2**, hunk 直接 FAILED 喵~

排查过程中发现 `pkgs.patchelf.version` 在不同 rev 上不一致喵:
`02c087f` (2026-10-20) 是 0.19.2, `d4f25a3` (2026-11-11) 退回 0.15.2 喵,
说明 nixpkgs 中途回退过 patchelf 喵~

结论: 新增 `nixpkgs-hermes = github:NixOS/nixpkgs/02c087f...` 并让 hermes 的
`inputs.nixpkgs.follows = "nixpkgs-hermes"` 喵~ 更稳的做法其实是直接锁上游 tag,
让上游 flake.lock 决定 nixpkgs 喵~

## 坑 2: `~/.cache/nix/tarball-cache-v2` 整个目录消失

求值时报 `writing packfile: -1 ... refs/: No such file or directory` 喵~
磁盘被打满后自动 GC 期间这个缓存目录被清掉了喵, Nix 期望它是 git 仓库喵~
处理: `rm -rf ~/.cache/nix/tarball-cache-v2` 让它重建, 不要手动 `mkdir` 子目录喵
(手动建了反而报 `could not find repository`) 喵~

## 坑 3: 磁盘只剩 2.6G 触发 daemon 自动 GC

本机 `min-free = 5GiB` / `max-free = 10GiB` 喵, 构建期间 Nix daemon 反复
"deleting garbage" 喵~ 默认行为是对的 (防止 ENOSPC), 但要意识到 GC 与构建并发时
日志会混在一起, 别误判成构建输出喵~

## 多 agent 协作设计 (Paseo)

核心三条不变量喵:

1. 一个任务 = 一个 worktree = 一个分支 = 一个 owner agent 喵~
2. 同一分支同一时刻只允许一个 agent 写喵~
3. 合并只有一个执行者 (交互 session 或用户), 并行 worker 只交 diff + 验证结果喵~

Paseo 提供的是**隔离**(每个 workspace 独立 worktree/分支)和**编排**(agent 之间可
互相派活、审 diff) 喵~ 它**不**替我们合并冲突喵~ 冲突从"同时改"推迟到"合并时"喵,
所以合并纪律仍然靠 AGENTS.md 三级工作流 + 本机 `VALIDATE_CMD` 喵~

知识层的边界也要注意喵: worktree 里的 `.agents/` 是分支副本喵,
kb 索引只覆盖主 checkout 喵~ 所以复盘/知识更新只在主 checkout 写喵~

## 验证

- `nix build .#nixosConfigurations.NixMEOW.config.system.build.toplevel` 通过喵~
- `hermes --version` / `paseo --version` 可用, `systemctl status hermes-agent paseo` active 喵~
- 浏览器打开 `http://127.0.0.1:6767` 出 Paseo web UI 喵~
