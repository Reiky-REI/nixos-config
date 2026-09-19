---
date: 2026-09-20
module: Reiky-nixpkgs/pkgs/opencode-v2, modules/development/opencode/default.nix, modules/services/opencode-root.nix, flake.lock
tags: [opencode, v2, Reiky-nixpkgs, bun, patchelf, serve, mcp-agents-bridge]
layer: services
severity: high
related:
  - ../conventions.md (打包归属)
  - ../known-issues.md (bun 单文件二进制 / v2 serve 鉴权)
experience:
  - "bun compile 的单文件二进制禁止 autoPatchelfHook/strip — 会破坏 ELF 尾部应用负载, 二进制退化成裸 Bun (--version 打印 Bun 版本); 需 dontPatchELF+dontStrip"
  - "major 版本升级前先起测试实例验证对外契约: v2 serve 新增强制密码鉴权 (无关闭开关), 直接换包会打断依赖 v1 无鉴权 API 的 bridge"
  - "CLI 升级与内部通道解耦: 系统 CLI 走 v2, root 通道通过 package 选项显式 pin v1, 一次 switch 两不误"
---

# OpenCode v2 采用（CLI=v2, root 通道 pin v1）

## 背景
nixpkgs 至今只收录 v1（unstable 1.18.x），v2 已发布 `2.0.10` 且经 npm 平台包分发预编译二进制喵~ 按约定打包进 Reiky-nixpkgs 喵~

## 打包（pkgs/opencode-v2）
- `fetchurl` 取 `@opencode/cli-linux-x64@2.0.10`（198MB 单文件，仅依赖 glibc）
- **关键坑**：首版加了 `autoPatchelfHook` → 装出来的二进制 `--version` 打印 **Bun 1.4.2**、`--help` 是 Bun 的帮助，等于应用负载被破坏喵~ 去掉 patchelf/strip（`dontPatchELF`/`dontStrip`）后恢复正常 `opencode v2.0.10`喵~
- 无 build/configure 步骤，`install -Dm755 bin/opencode` 收工喵~

## serve 契约变更（决定性）
v2 的 `opencode serve` **强制密码鉴权**：启动打印随机 `server password`，无鉴权请求返回 **401**；`--help` 里没有任何关闭开关喵~ 而 `mcp-agents-bridge` 调的是 v1 无鉴权 API（`POST /session`、`POST /session/{id}/shell`）→ 直接把系统 opencode 换成 v2 会打断 root 高级权限通道喵~

## 采用策略
- `modules/development/opencode/default.nix`：系统 CLI 用 `pkgs.opencode-v2`
- `modules/services/opencode-root.nix`：新增 `package` 选项，**默认 pin `pkgs-unstable.opencode`（v1）**，`ExecStart` 改用该包绝对路径（不再依赖 `/run/current-system/sw/bin/opencode`）
- 两者同名二进制不会 PATH 冲突（v1 只以 store 路径被服务引用）喵~

## 待办
1. v2 的 `serve` 鉴权若上游支持配置/关闭，或改造 bridge 支持 Basic Auth，可把 root 通道也升级
2. `opencode-gc` 定时器脚本仍指向 `opencode-stable.db`（v1 命名），v2 数据落盘位置待核对
3. nixpkgs 收录 v2 后应转为直接引用官方包
