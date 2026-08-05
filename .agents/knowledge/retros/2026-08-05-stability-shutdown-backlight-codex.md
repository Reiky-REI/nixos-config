---
date: 2026-08-05
module: hosts/MEOW/hardware.nix, modules/desktop/default.nix, modules/common/default.nix, modules/networking/tailscale.nix, flake.nix, pkgs/tuxedo-drivers-patched/
tags: [mt7921e, aspm, shutdown, brightnessctl, tuxedo-keyboard, 键盘背光, codex, ly, 稳定性]
layer: hardware
severity: medium
related:
  - ../../known-issues.md (mt7921e ASPM / 关机慢)
---

# 复盘: 长时间运行稳定性 + 关机慢 + 亮度键 + 键盘背光 + codex

## 背景

用户长期不关机使用 (Linux 常态), 反馈 4 类问题:
1. 长时间运行后 WiFi 掉线 (mt7921e driver own failed / chip reset failed)
2. 关机慢/黑屏关不死/风扇满速 (8/3 关机耗时 3分48秒)
3. ly 登录界面调亮度失败
4. 内置键盘背光只能蓝光, 熄屏后太亮

## 诊断结论 (日志证据)

### mt7921e WiFi 掉线
- 7/27、8/3 日志: `mt7921e: driver own failed`、`Message timeout`、`chip reset failed`
- 根因: `/sys/module/mt7921e/parameters/disable_aspm = N`, AMD 平台 ASPM 电源管理 bug
- 蓝牙侧早有 btusb autosuspend 禁用补丁, WiFi 侧漏了

### 关机慢 (3分48秒)
- **nvme1 (SOLIDIGM 1TB Windows 盘) I/O 超时 × 7 次, 每次 30 秒** — 主元凶
  - nvme1 SMART 健康, unsafe_shutdowns=64 (Windows 侧频繁强关)
  - hiberfil.sys 存在 (6.8GB) → Windows 快速启动曾启用
  - 但 NTFS 卷干净无脏标记, 纯属关机时 flush 卡住 + 默认 90s 超时叠加
- NVIDIA GSP 异常: `Xid 120 GSP task exception` + `Xid 154 GPU Reset Required` → 屏幕黑+风扇满速
- systemd 默认 DefaultTimeoutStopSec=90s, 硬件 watchdog 10min

### ly 亮度键失败
- **根因: niri 配置引用了 `brightnessctl` 但系统没装** → ly TTY 界面和桌面按亮度键全部无效
- ly 是 TTY 登录界面, 不内置亮度处理, 需要 acpid 捕获 ACPI video 事件

### 键盘背光
- COLORFIRE MEOW R16 24H = Clevo/Tongfang 模具 (WMI GUID ABBC0F6B/6D 匹配)
- 固件误报背光类型 0x26, tuxedo_keyboard 不注册 LED
- 找到开源方案: github.com/JAmanOG/colorful-p15-keyboard-backlight

## 改动

| 文件 | 内容 |
|------|------|
| `hosts/MEOW/hardware.nix` | `options mt7921e disable_aspm=Y`; 启用 `hardware.tuxedo-drivers` + `options tuxedo_keyboard force_clevo_kb_backlight_type=6` |
| `modules/common/default.nix` | `systemd.settings.Manager.DefaultTimeoutStopSec = "30s"` (注意: 25.11 用 settings 而非 extraConfig!) |
| `modules/desktop/default.nix` | 系统级装 brightnessctl; udev 规则授权 video 组写 backlight/leds; acpid 处理 video/brightnessup-down (有 seat0 会话时跳过, 避免与 niri 双触发) |
| `modules/networking/tailscale.nix` | 修 `--timeout 5` → `--timeout=5s` (必须带单位, 否则 parse error) |
| `pkgs/tuxedo-drivers-patched/` | nixpkgs 4.18.0 + no-cp-usr.patch + kbdlight.patch (force_clevo_kb_backlight_type) |
| `flake.nix` | overlay: `linuxPackages.extend` 替换 tuxedo-drivers/tuxedo-keyboard |
| `home/Reiky-REI/dev/codex.nix` | codex 安装 + DeepSeek provider + AGENTS.md 桥接 |
| `home/Reiky-REI/tools/kbdlight.nix` | kbdlight 脚本 (off/on/亮度/RGB) |
| `AGENTS.md` (仓库根) | Codex 入口索引, 桥接 .agents/ 体系 |
| `opencode.json` | 权限升级: switch/boot/push 改 allow, 新增 shutdown/poweroff allow |

### fcitx5 快捷键修复 (同批次)
- 根因: nix 配置 `Hotkey/EnumerateForwardForInputWindow` 是**无效键名**, fcitx5 不识别 → Shift 单按切换中英从未生效, 只能点托盘图标
- 修正: `AltTriggerKeys` (Shift 单按) + `TriggerKeys` (Super+space / Ctrl+Space) + `EnumerateForwardKeys` (Ctrl+Shift)
- 经验: fcitx5 的 `config` 文件键名以实际生成为准, 对照 `~/.config/fcitx5/config` 验证

## 验证

- `nixos-rebuild build --flake /etc/nixos#NixMEOW` 通过
- 补丁编译进 tuxedo_keyboard.ko: strings 确认 `force_clevo_kb_backlight_type` + `rgb:kbdlight`
- 系统隔夜 6h43m 运行无新错误 (但旧配置未应用, 需 switch/重启生效)

## 经验

1. **NixOS 25.11 `systemd.extraConfig` 已废弃** → 报错 "no longer has any effect; please remove it", 用 `systemd.settings.Manager` 替代
2. **mt7921e disable_aspm 是 AMD 平台标配** — 该网卡+AMD CPU 组合的长期运行稳定性修复
3. **ly 界面亮度键链路**: ly (TTY) → 内核 ACPI video 事件 → acpid → brightnessctl; 桌面 → niri XF86 绑定。两者用 seat0 会话检测避免双触发
4. **flake 新文件必须 git add 才可见** — flake 只跟踪 git 文件, 新文件未 add 时 eval 报 "path does not exist"
5. **Clevo/Tongfang 模具键盘背光**: nixpkgs tuxedo-drivers 打 kbdlight patch 即可, overlay 通过 `linuxPackages.extend` (不是 nixpkgs 顶层 tuxedo-drivers!)
6. **tailscale `--timeout` 必须带单位** (如 `5s`), 裸数字 parse error 且静默失败
