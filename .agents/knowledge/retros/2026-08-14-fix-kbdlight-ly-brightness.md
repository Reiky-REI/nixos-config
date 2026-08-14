---
date: 2026-08-14
module: home/Reiky-REI/tools/, modules/desktop/default.nix, pkgs/tuxedo-drivers-patched/
tags: [kbdlight, tuxedo-keyboard, 键盘背光, ly, brightness, acpid, DMI, COLORFIRE]
layer: home + hardware
severity: high
related:
  - ../../known-issues.md
  - ./2026-08-05-stability-shutdown-backlight-codex.md
---

# 复盘: 修复 ly 亮度调节 + Mod+Shift+P 黑屏 + 键盘背光 (三连失效)

## 背景

用户反馈上次升级/重构后三个功能同时失效喵~ :
1. ly 登录界面亮度调节用不了喵~ 
2. Mod+Shift+P 黑屏用不了喵~ 
3. 键盘背光控制不了喵~ 

## 根因分析 (三连失效同源)

排查发现三个问题来自 opencode 8/5 提交 (05af4aa + 7b73a72) 的**未接线/未生效**喵~ :

### 根因 1: kbdlight.nix 从未被 import
`home/Reiky-REI/tools/default.nix` 的 imports 列表从创建起就**没有 `./kbdlight.nix`**喵~ 
opencode 写了 kbdlight.nix (kbdlight 命令 + kbdlight-sync 守护 + kbdlight-niri-off.sh) 但忘记接进模块喵~ 
→ kbdlight 命令/脚本/服务全部未生成喵~ 

### 根因 2: tuxedo_keyboard 模块加载失败 (-ENODEV)
`tuxedo_is_compatible()` 只匹配 DMI 厂商 "TUXEDO" 喵~ 
本机 DMI 是 **COLORFIRE** (Clevo/Tongfang 模具) 喵~ 
→ 模块 init 直接返回 `-ENODEV` (No such device) 喵~ → /sys/class/leds/rgb:kbdlight 设备不存在喵~ 

### 根因 3: ly 亮度键 acpid handler 误判
`modules/desktop/default.nix` 的 acpid handler 用 `grep -q seat0` 判断"有无图形会话"喵~ 
但 ly 登录界面 (TTY) 时 logind 也给 tty1 挂 seat0 会话喵~ 
→ handler 误判"有图形会话"而跳过 → ly 界面亮度键无效喵~ 

## 修复内容

| 文件 | 修改 |
|------|------|
| `home/Reiky-REI/tools/default.nix` | imports 加 `./kbdlight.nix` |
| `pkgs/tuxedo-drivers-patched/compat-check.patch` (新增) | `tuxedo_dmi_string_match` 加 `DMI_MATCH(DMI_SYS_VENDOR, "COLORFIRE")` |
| `pkgs/tuxedo-drivers-patched/default.nix` | patches 加 `./compat-check.patch` |
| `modules/desktop/default.nix` | acpid handler 改判断 active wayland/x11 会话 (不再用 seat0) |

## 验证

- `nix build .#nixosConfigurations.NixMEOW.config.boot.kernelPackages.tuxedo-drivers` ✅ 编译成功
- 新模块字符串检查: `tuxedo_compatibility_check.ko` 含 `COLORFIRE` ✅
- `nix eval` 确认 home.file 生成 `kbdlight-niri-off.sh` + `kbdlight-sync.py` + `kbdlight-sync` 服务 ✅
- acpid handler 逻辑: 桌面有 active wayland 会话 → 跳过 (niri 处理); ly 界面无 → acpid 处理 ✅

## 经验

1. **flake 只跟踪 git 文件** — 新 patch 必须先 `git add` 否则 eval 报 "path does not exist" (复盘 8/5 也踩过)
2. **tuxedo-drivers 兼容性检查是硬门槛** — 只认 DMI "TUXEDO", 白牌 Clevo/Tongfang 模具必须补丁放行
3. **判断"有无图形会话"不能用 seat0** — ly TTY 界面也挂 seat0, 要查 Type=wayland/x11 + Active
4. **opencode 写文件≠接线** — kbdlight.nix 创建 9 天从未被 import, 需检查 imports 完整性
5. **磁盘瓶颈** — 26.05 全量升级需 20G+ 解压空间, 当前 14G 不够, coredump 4G + GC 4G 可清 (已清理)

## 遗留

- 26.05 全量 build 因磁盘不足未完成, 修复代码保留在 upgrade/nixos-26.05 分支喵~ 
- 应用需: 磁盘扩容或清理 waydroid (6G) 后 `nixos-rebuild build` + 重启 (内核模块变更) 喵~ 
