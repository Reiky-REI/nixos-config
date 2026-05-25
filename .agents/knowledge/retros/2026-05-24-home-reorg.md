# 复盘: 2026-05-24/25 Home 重组 + 蓝牙 + 快捷键 + NVIDIA

## 目标
1. 重组 home/Reiky-REI/ 目录 (desktop/apps/tools/editors/dev)
2. NVIDIA PRIME 卸载配置 (RTX 4070 + AMD 核显)
3. 统一 Hyprland/Niri 快捷键 + Fcitx5 优化
4. 诊断 MediaTek MT7922 蓝牙 -22 错误

## 关键提交
- `72c0edd` feat: home重组 + NVIDIA PRIME + 内核6.12LTS + 快捷键统一 + 输入法配置
- `1f86ffb` fix: clash WM层启动 + btusb参数 + niri config修复
- `57d169c` fix: MediaTek MT7922 蓝牙内核补丁 + knowledge 文档体系
- `615a7fe` docs: 重构知识体系 — 三份核心文档 + 排障/Session 日志整合
- `3a298e6` chore: 回退 patched kernel, 补充编译进度查看文档

## 遇到的坑

### 坑 1: Niri submap 导致配置失效
- **现象**: Niri 启动后配置解析失败，快捷键不生效
- **根因**: Niri 不支持 Hyprland 的 block-based `submap` 语法
- **解决**: 改用 `switch-to-named-submap` + `switch-to-previous-submap`（keyword-based）
- **结果**: ✅ 已解决
- **下次注意**: Niri 用 keyword-based submap，不是 block-based

### 坑 2: swaync/swayidle 误放 NixOS modules
- **现象**: `attribute 'swaync' not found`
- **根因**: swaync/swayidle 是 home-manager 的 `services.*`，不是 NixOS 的
- **解决**: 从 `modules/desktop/` 移回 `home/Reiky-REI/`
- **结果**: ✅ 已解决
- **下次注意**: 先查选项归属，是 `services.*` 还是 `hm.services.*`

### 坑 3: linuxPackages_lts 不存在
- **现象**: `nixos-rebuild` 报找不到 `linuxPackages_lts`
- **根因**: nixpkgs 25.11 没有 `linuxPackages_lts` 这个 attribute
- **解决**: 改为 `linuxPackages_6_12`
- **结果**: ✅ 已解决

### 坑 4: 蓝牙 MT7922 -22 错误
- **现象**: `hci0: Failed to send wmt func ctrl (-22)`
- **根因**: 内核 commit 634a4408c061 严格校验 WMT 事件包长，MT7922 固件发短包
- **解决**: 打上游 commit e3ac0d9f1a20 等价补丁，需要全量编译内核（~2h）
- **结果**: ⏳ 补丁已就绪，等待全量编译
- **下次注意**: 全量编译时用 `systemd-run` 后台跑，用 `journalctl -u nix-rebuild -f` 看进度

### 坑 5: NVIDIA PRIME Bus ID
- **现象**: PRIME 卸载后独显调用无效
- **根因**: Bus ID 配置错误
- **解决**: `nvidiaBusId = "PCI:0:1:0:0"`, `amdgpuBusId = "PCI:0:6:0:0"`
- **结果**: ✅ 已解决，`nvidia-offload <command>` 正常

## 本次沉淀
- [x] 提炼到 known-issues.md → Niri submap/属性名, swaync 归属, linuxPackages_lts, 蓝牙, NVIDIA
- [x] 创建 rebuild skill → 长时间编译 + 加速编译命令
