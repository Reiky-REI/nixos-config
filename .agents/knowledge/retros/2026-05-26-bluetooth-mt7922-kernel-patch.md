# 复盘: 蓝牙 MT7922 内核补丁（避免全量编译）

## 目标
为 MT7922 蓝牙芯片打 btmtk WMT 事件校验补丁，解决 `hci0: Failed to send wmt func ctrl (-22)`，且**不触发全量内核编译**（之前两次 timeout）。等上游 6.12.91+ / 7.1-rc1+ 进入 nixpkgs 后移除。

## 关键提交
- `07ed50c` chore: 汇总本周AI修改（含 btmtk-fix.nix）

## 方案：只编译 btmtk.ko，跳过全量内核

**原理**：利用 kbuild 的 `make -C buildtree M=srcdir modules`，只编译 `drivers/bluetooth/btmtk.c` 一个文件。

**优化措施**：
- 从 tarball 只提取 `btmtk.c` + `btmtk.h`（2 文件 vs 1GB 源码）
- 复用 `kernel.dev` 的 build tree（跳过 `modules_prepare` 的 10 分钟）
- `-O1 -g0` 降低优化（`-O0` 会因 `asm goto` 报错）
- 自建 `Kbuild`（`obj-m := btmtk.o`），不依赖原始 Makefile
- 产物通过 `boot.extraModulePackages` 注入 `updates/` 目录

**耗时**：`nixos-rebuild switch` 仅 44 秒（含构建 + 激活 + agenix 解密）。

## 涉及的坑

### 坑 1: `boot.kernelPatches` 会全量编译内核
- **现象**: 之前两次 `nixos-rebuild` timeout
- **根因**: `kernelPatches` 改变 kernel derivation hash，触发全量编译 1-3h
- **解决**: 不走 `kernelPatches`，改用独立 derivation + `boot.extraModulePackages`
- **下次注意**: 单个内核模块的补丁不需要动 kernel 本身

### 坑 2: `stdenv.mkDerivation` 默认需要 `src`
- **现象**: `variable $src or $srcs should point to the source`
- **根因**: 默认 `unpackPhase` 要求 `$src` 存在，但我们要手动提取 tarball
- **解决**: `phases = [ "buildPhase" "installPhase" ]` 跳过 unpack 阶段
- **结果**: ✅

### 坑 3: `-O0` 与内核 `asm goto` 不兼容
- **现象**: `error: impossible constraint in 'asm'` — `jump_label.h` / `bug.h` 报错
- **根因**: 内核 `arch_static_branch` 宏依赖 `asm goto`，要求至少 `-O1`
- **解决**: `KCFLAGS="-O1 -g0"`（`-O1` 仍有基本优化，但比 `-O2` 快很多）
- **结果**: ✅
- **下次注意**: 内核模块编译最低 `-O1`，`-O0` 对 Linux 内核不可行

### 坑 4: Flake eval 可能不包含未 commit 的文件
- **现象**: gen 93（`switch` 前）没有带上补丁，但 `dry-activate` 却有
- **根因**: 文件在 gen 93 构建时**已 `git add` 但未 commit**，`builtins.fetchGit` 在不同 nix 调用间行为不一致
- **解决**: commit 后再 `nixos-rebuild switch`，文件在 HEAD 树中确保被包含
- **下次注意**: Flake 文件的改动必须 commit 后再 nixos-rebuild，不要依赖 `git add` 后的 dirty 状态

### 坑 5: `switch` 不会 reload 内核模块
- **现象**: `switch` 后 `dmesg` 仍看到启动时的 `-22` 错误
- **根因**: `dmesg` 是 boot-time 日志，`switch` 不替换已加载到内核的模块
- **解决**: `modprobe -r btmtk && modprobe btmtk` 或 `reboot`
- **下次注意**: 说明 `dmesg` 日志非实时状态，需解释清除

### 坑 6: `build` 模式未正确创建 generation
- **现象**: 告诉用户跑 `build` + `reboot`，但 `build` 不会更新 bootloader
- **根因**: `nixos-rebuild build` 仅构建 + 设置 profile，不写 boot 条目
- **正确做法**: `switch`（不惧 NVIDIA 风险时）或 `boot` + `reboot`
- **下次注意**: 区分 `build` / `boot` / `switch` 的实际行为

## 本次沉淀
- [x] 提炼到 known-issues.md → 已有 BT MT7922 条目，补丁已应用
- [x] 复盘文档 → `.agents/knowledge/retros/2026-05-26-bluetooth-mt7922-kernel-patch.md`
