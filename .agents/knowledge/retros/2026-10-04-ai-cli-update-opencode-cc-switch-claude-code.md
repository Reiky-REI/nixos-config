---
date: 2026-10-04
module: home/reiky/dev, hosts/NixMEOW/hardware.nix, flake.lock
tags: [opencode, cc-switch, claude-code, nixpkgs-bump, kernel, multi-agent, collab]
layer: mixed
severity: medium
related:
  - ../../known-issues.md
  - ../../../Reiky-nixpkgs
---

# 复盘: AI CLI 三件套升级 (opencode v2 / cc-switch / claude-code) + nixpkgs bump (2026-10-04)

## 背景

用户要求更新 opencode / cc-switch / claude-code 喵~ 当时有三个 AI agent 并行
(opencode cc-switch 线 / opencode net-tolaria 线 / dsh 线), 故用独立 worktree +
协作消息板 + 资源锁隔离喵~

## 变更

### 1. 私源 Reiky-nixpkgs (main 尖端 = `7655711`)

- `opencode-v2` 2.0.10 → **2.0.22** (npm 平台包 `@opencode/cli-linux-x64`, 仅改 version/url/hash)
- 新增 `pkgs/cc-switch` **5.10.5** (GitHub Release `linux-x64` tar.gz)
  - `dontPatchELF`/`dontStrip` 保上游字节, `sourceRoot="."` 处理 tar 内单文件无顶层目录
  - 动态链接由系统 `programs.nix-ld` 兜底
  - 取代原手装在 `~/.local/bin/cc-switch` 的 5.6.1 (非声明式; 且 `~/.local/bin` 在 PATH 里
    优先于 profile, 会盖住 nix 版)
- 注意: dsh 的 `e50e796` 是 `7655711` 的祖先, 故合 main 时以本线为准即可带上 dsh 包

### 2. 主仓 `/etc/nixos` (`feat/opencode-cc-switch-bump` → `f0203ea`)

- 新增 `home/reiky/dev/cc-switch.nix` + import; flake.lock `Reiky-nixpkgs f4406e6 → 7655711`
- claude-code: 按用户决策走**官方源**, flake.lock `nixpkgs 445d8618 → 774debe7`
  (nixos-26.05, 2026-10-02), claude-code `2.1.187 → 2.1.223`

## 踩坑: nixpkgs bump 触发内核 EOL (关键)

- **现象**: bump 后 `nixos-rebuild build` 秒挂在 eval 阶段 —
  `error: linux 7.1 was removed because it has reached its end of life upstream`
- **根因**: `hosts/NixMEOW/hardware.nix` 的 fallback `boot.kernelPackages = pkgs.linuxPackages_7_1`
  在新 nixpkgs 已移除喵~ 虽然**实际**内核由 `kernel-715` 特性
  (`lib/mk-host.nix` 用 `nixpkgs-715` pin = 7.1.5, `lib.mkForce` 覆盖) 提供,
  但**被覆盖的定义仍会被求值** → 抛错喵~
- **修复** (`f0203ea`): fallback 改为 `pkgs.linuxPackages_6_12` (文档既有的退回选择);
  实际内核不受影响 (仍 7.1.5)喵~
- **教训**: nixpkgs bump 是全系统级; 任何 `pkgs.<已 EOL 属性>` **即使被 `mkForce` 覆盖
  也会在 eval 期炸**喵~ bump 前先干跑/`nix eval` 一遍, 别等 merge 后才发现喵~

## 多 agent 协作要点

- **独立 worktree 隔离**: 主仓用 `nixmeow-wt-opencode-cc`, 不动 DSH 在 `/etc/nixos`
  的 `feat/dsh-0.2.0-upgrade` 工作区; 私源也开了临时 worktree (完成后已清理)喵~
- **`rebuild` 锁串行构建**: 我先跑了 pre-merge build 发现 kernel 坑, 修完后**主动 kill +
  释放锁**, 让 net 合并后**只 build 一次**, 避免两份全量 nixpkgs 重建浪费带宽喵~
- **消息板 + 协作层**: `dialogue.sh` (说什么) + `agent-collab` 的
  `wake.sh`/`collab.sh` (叫醒谁/谁做什么/锁)喵~
  - ⚠️ `opencode run` 默认 **plan(只读)**, 唤醒模板必须带 `--agent build` 才能干活喵~
- **flake.lock 交叠**: 以本线 `f0203ea` 为基 (Reiky-nixpkgs=7655711 + 官方 nixpkgs=774debe7),
  dsh 的 flake.lock 增量已被包含, 不冲突喵~

## 待办 (本线之后, 由合并方/后续处理)

- net 统一合 main → cc-switch 跑 `cc-switch-build-verify` → dsh 最终 `nixos-rebuild switch`
- ⚠️ **switch 后必须删除 `~/.local/bin/cc-switch`** (否则遮蔽 nix 版, 仍是旧 5.6.1)喵~
- `cc-switch update` 在只读 store 下会失败, 属预期; 升级一律走 nix 喵~
- `~/.cc-switch/` 配置与 `~/.local/state/cc-switch/` 状态目录不受影响喵~

## 验证

- 私源: `nix build .#opencode-v2 .#cc-switch` 通过;
  `opencode --version` = v2.0.22, `cc-switch --version` = 5.10.5, `cc-switch provider list` 正常喵~
- 主仓: `nix eval` 通过 (claude-code=2.1.223, cc-switch=5.10.5, home.packages 含 cc-switch);
  kernel 修复后 `nixos-rebuild build` 通过 eval 进入构建阶段 (pre-merge, 已由 net 合并后统一 build)喵~
