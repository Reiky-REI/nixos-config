---
date: 2026-10-03
module: home/reiky/tools/deepsec.nix, home/reiky/tools/default.nix, flake.lock, Reiky-nixpkgs:pkgs/deepsec-tui, Reiky-nixpkgs:pkgs/deepsec-lsp
tags: [deepsec, tui, rust, nix, flake, reproducible, reiky-nixpkgs, security]
related: []
---

# 复盘: DeepSec TUI/LSP 原生二进制 Nix 化(可重复构建)

## 背景 / 症状

`deepsec tui` 报:

```
DeepSec TUI binary was not found. Install a DeepSec release, build `tui/`, or set DEEPSEC_TUI_BINARY.
```

根因: DeepSec 的 TUI 是独立 Rust crate(`tui/`,ratatui/crossterm),不随 Python 包分发喵~
`deepsec/cli/tui.py::_find_binary()` 依次找 `$DEEPSEC_TUI_BINARY` → PATH 上的
`deepsec-tui-native` → `<repo>/tui/target/release/deepsec-tui-native`,三处全空喵~
此前从未 `cargo build`,故报错喵~

## 方案(用户要「nix-flakes 方式可重复构建」)

把两个 Rust crate 收进 `Reiky-nixpkgs` 私源(与 `pkgs/dsh`/`pkgs/zen-browser` 同模式),
`/etc/nixos` 经 overlay 声明式安装喵~ Python 运行时(deepsec/deepsec-guard CLI)仍走
`~/WorkSpace/DeepSec` 的 pixi 环境(pixi.lock 已锁定),本次只补此前缺失的原生二进制喵~

### 改动

`Reiky-nixpkgs`:
- `pkgs/deepsec-tui/default.nix` — `rustPlatform.buildRustPackage`,产出 `deepsec-tui-native`
- `pkgs/deepsec-lsp/default.nix` — 同上,产出 `deepsec-lsp`(rusqlite bundled)
- `flake.nix` — overlay + packages 各注册两项
- 两包均 `fetchFromGitHub` 钉死上游 rev `fff031f`,并用源码自带 `Cargo.lock`
  (`cargoLock.lockFile`),crates 依赖树完全复现喵~
- 子目录构建要点:同时设 `cargoRoot = "<subdir>"`(定位 lockfile)与
  `buildAndTestSubdir = "<subdir>"`(pushd 后再 cargo build),只设一个不够喵~

`/etc/nixos`:
- `home/reiky/tools/deepsec.nix` — `home.packages += [ pkgs.deepsec-tui pkgs.deepsec-lsp ]`
- `home/reiky/tools/default.nix` — 在 `system == "x86_64-linux"` 时 import(Reiky-nixpkgs
  的 `supportedSystems` 仅 x86_64-linux)喵~
- `flake.lock` — Reiky-nixpkgs input bump 到含新包的 main rev `2c239b8`

## 验证

- `nix build .#deepsec-tui` / `.  #deepsec-lsp`(Reiky-nixpkgs):成功;
  buildRustPackage 默认跑测试: **tui 41 项、lsp 2 项全过**喵~
- `/etc/nixos`:`nixos-rebuild build --flake /etc/nixos#NixMEOW` 成功,
  产物 `result/etc/profiles/per-user/reiky/bin/{deepsec-tui-native,deepsec-lsp}` 到位喵~
- 切换后 `deepsec tui` 的 `shutil.which("deepsec-tui-native")` 即命中喵~

## 踩坑 / 要点

1. **`/etc/nixos` 的 flake input 指向 GitHub,不认本地 clone**喵~ 改 `Reiky-nixpkgs`
   必须 commit + push main,再 `nix flake update Reiky-nixpkgs` 才能生效喵~
   (集成验证阶段可先用 `--override-input Reiky-nixpkgs path:...` 本地预演)喵~
2. **并发 agent**:本次执行期间另有 agent 提交了 Tolaria 包并推进了两仓 main喵,
   P0 的旧 ref 快照一度与实时状态不符喵~ 动手前重新 `git fetch` + `reflog` 核对喵~
3. `node` 裸 import `@deepseek-ai/dsh-tools` 会经 `~/WorkSpace/node_modules/@deepseek-ai`
   软链命中 store 里的真实 dsh-tools,导致上游 `dsh-plugins/test/smoke.mjs` 第 5 步
   由 schema 提前拦截(缺 `authorized` 抛 ToolArgsError)而非走插件 guard喵~
   把 dsh-plugins 拷到 /tmp(祖先无 node_modules)即走 passthrough,全套 9 项通过喵~
   两种路径下**授权门禁均成立**喵~

## 遗留

- Python 可选 extras(reportlab/mitmproxy/playwright)未装,见后续步骤喵~
- `~/.deepsec/config.yaml` 待 `deepsec config init` 生成喵~
