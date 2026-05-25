# NixMEOW 系统维护手册 (AI 参考)

> 本手册供 AI agent 理解和维护本 NixOS 仓库使用。

## 1. 架构概览

```
flake.nix
  ├── nixConfig          ← 镜像源 (TUNA/USTC/cache.nixos.org)
  ├── inputs             ← 依赖 (nixpkgs, home-manager, catppuccin, agenix, niri, ...)
  └── outputs.NixMEOW
       ├── hosts/MEOW/default.nix  ← composition root (仅 imports + host-specific)
       │    └── modules/            ← 系统模块聚合
       └── home/Reiky-REI/         ← home-manager 用户层
```

**命令映射**: `flake.nix#NixMEOW` → `hosts/MEOW/default.nix` → `modules/*` + `home/Reiky-REI/*`

## 2. 目录树速查

| 路径 | 职责 | 放什么 | 不放什么 |
|------|------|--------|----------|
| `modules/common/` | 全局基础 | nix settings, timezone, i18n, fonts, zsh, sudo | 桌面策略, 硬件驱动 |
| `modules/hardware/` | 硬件策略 | microcode, GPU, bluetooth, intel-media-driver, firmware | 软件包, 服务 |
| `modules/desktop/` | 桌面基础 | hyprland/niri 系统启用, ly DM, xwayland, steam, fcitx5 配置, 通知, idle | 用户态 WM 配置文件 |
| `modules/networking/` | 网络 | NetworkManager, 代理, 防火墙, SSH, clash | 浏览器, 应用 |
| `modules/services/` | 系统服务 | pipewire, mpd, flatpak, CUPS, udisks2, timesyncd, 电源管理, polkit | 用户交互应用 |
| `modules/development/` | 开发工具链 | wine, winetricks, CUDA | 编辑器 (放 home) |
| `home/Reiky-REI/` | 用户态 | `desktop/` WM 配置, `apps/` GUI 应用, `tools/` CLI 工具, `editors/`, `dev/`, shell, terminal, music | daemon, 内核参数 |
| `secrets/` | 加密密钥 | agenix 加密文件 | — |

## 3. 分层决策规则

```
daemon / 后台长期运行  → modules/services/
图形会话入口 / WM 栈   → modules/desktop/
用户交互应用 / 偏好    → home/Reiky-REI/
硬件驱动 / 微码        → modules/hardware/
全局基础设置           → modules/common/
```

### 环境变量归属
| 变量 | 模块 |
|------|------|
| `NIXOS_OZONE_WL` | `modules/desktop/` |
| `GTK_IM_MODULE`, `QT_IM_MODULE`, `QT5_IM_MODULE`, `XMODIFIERS` | `modules/desktop/fcitx5/` |
| `TERMINAL` | `home/Reiky-REI/` |
| `XDG_DATA_DIRS` (flatpak) | `modules/services/` |

## 4. 关键模块索引

| 功能 | 文件 |
|------|------|
| 系统入口 | `flake.nix` |
| Host 聚合 | `hosts/MEOW/default.nix` |
| 硬件 | `hosts/MEOW/hardware.nix`, `modules/hardware/default.nix` |
| 输入法 (fcitx5) | `modules/desktop/fcitx5/fcitx5.nix` |
| Hyprland 系统启用 | `modules/desktop/default.nix` |
| Hyprland 用户配置 | `home/Reiky-REI/desktop/hyprland/` |
| Niri 配置 | `home/Reiky-REI/desktop/niri/` |
| Shell (zsh) | `home/Reiky-REI/shell/zsh.nix` |
| 终端 | `home/Reiky-REI/terminal/{kitty,alacritty}.nix` |
| 应用 | `home/Reiky-REI/apps/{browser,communication,media,office}.nix` |
| CLI 工具 | `home/Reiky-REI/tools/` |
| 编辑器 | `home/Reiky-REI/editors/neovim.nix` |
| 开发工具 | `home/Reiky-REI/dev/` |
| 桌面组件 (rofi/wallpaper/rofi) | `home/Reiky-REI/desktop/` |

## 5. 已知问题 & 注意事项

### 5.1 catppuccin 兼容性
`catppuccin` release-25.11 版本中**以下子模块不可用**，已全部注释：
- `catppuccin.alacritty`, `catppuccin.bat`, `catppuccin.btop`, `catppuccin.cava`
- `catppuccin.chromium`, `catppuccin.fuzzel`, `catppuccin.fzf`, `catppuccin.imv`
- `catppuccin.lazygit`, `catppuccin.mpv`, `catppuccin.swaync`, `catppuccin.tmux`

仅 `catppuccin.fcitx5` 可用。如需恢复主题，需先确认 catppuccin 版本是否更新。

### 5.2 fcitx5 输入法
- 添加新输入法包时必须在 `i18n.inputMethod.fcitx5.addons` 中加入 `fcitx5-gtk`
- `waylandFrontend = true` 时 NixOS 模块不设 `GTK_IM_MODULE`，需在 `environment.sessionVariables` 中手动设置
- fcitx5 的 XDG autostart 已被禁用，由 `niri/config.kdl` 的 `spawn-at-startup "fcitx5"` 统一管理
- 切换输入法快捷键: `Super+Space`

### 5.3 mpd.service 首次失败
- 首次 switch 后 mpd 可能报 `Address already in use`
- 解决: `sudo killall mpd && sudo systemctl start mpd`

### 5.4 已知内核补丁
MediaTek MT7922 蓝牙 `hci0: Failed to send wmt func ctrl (-22)` 错误。
- **根因**: 内核 commit `634a4408c061` 严格校验 WMT 事件包长度, MT7922 固件合法发送短包
- **修复**: 打上游 commit `e3ac0d9f1a20` 等价补丁 (6.12.91+ / 7.1-rc1+)
- **当前**: `patches/btmtk-wmt-fix.patch` 已打过, 待 nixpkgs 更新到含修复的内核后移除
- **加速编译**: `performance` governor + 停 `power-profiles-daemon` + `systemd-run` 避开超时

### 5.5 已知排障列表

| 问题 | 根因 | 修复 |
|------|------|------|
| Niri 配置失效, spawn-at-startup 全不执行 | Niri 26.04 不支持 submap, KDL 解析失败 | 用 `niri validate` 验证; 不用 submap |
| swaync/swayidle 移到 NixOS modules 报不存在 | 它们是 HM 选项, NixOS 没有 | 放在 `home/default.nix` |
| fcitx5 `"Behavior/OverrideEnabled"` 不存在 | fcitx5 NixOS module 的 settings 类型严格 | 只放预定义的 key |
| `linuxPackages_lts` 不存在 | nixpkgs 25.11 移除了 | 用 `linuxPackages_6_12` 或具体版本 |
| `nodejs_23` 不存在 | 只有 nodejs_22 | 用 `nodejs` |
| tmux `better-mousemode` 不存在 | nixpkgs 移除 | 删除该 plugin |
| vim `settings.clipboard`/`cursorcolumn` 不存在 | HM 25.11 严格类型 | 全部移入 `extraConfig` |
| `luajit` + `lua` 的 `luaconf.h` 冲突 | 两个包提供同文件 | 删 `luajit` |

### 5.6 代理与网络
- 代理: `http://127.0.0.1:7897`
- GitHub token: `.agent/config/token` (gitignore 保护)
- 镜像: TUNA, USTC
- Rebuild 脚本: `.agent/config/rebuild.sh` 自动注入 proxy + token

## 6. 操作命令

### Rebuild
```bash
# 验证 (不切换)
sudo .agent/config/rebuild.sh dry-activate

# 切换 (静默, 后台编译)
sudo .agent/config/rebuild.sh switch

# 切换 + 显示编译进度 (长时间编译时加 -v 可以看到具体在编哪个包)
sudo .agent/config/rebuild.sh switch -v
sudo .agent/config/rebuild.sh switch --verbose

# 手动
sudo env http_proxy=http://127.0.0.1:7897 https_proxy=http://127.0.0.1:7897 \
  NIX_ACCESS_TOKEN=$(cat .agent/config/token) \
  nixos-rebuild switch --flake /etc/nixos#NixMEOW \
  --option substituters "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store https://mirrors.ustc.edu.cn/nix-channels/store https://cache.nixos.org" \
  --option access-tokens "github.com=$(cat .agent/config/token)"
```

### 查看编译状态 (switch 正在跑时)

#### 方法 A: systemd-run 后台跑 (推荐, 不超时)
```bash
# 启动
sudo systemd-run --unit=nix-rebuild --description="NixOS rebuild" \
  --same-dir --working-directory=/etc/nixos \
  --setenv=http_proxy=http://127.0.0.1:7897 \
  --setenv=https_proxy=http://127.0.0.1:7897 \
  --setenv=NIX_ACCESS_TOKEN="$(sudo cat /etc/nixos/.agent/config/token)" \
  nixos-rebuild switch --flake /etc/nixos#NixMEOW --print-build-logs \
  --option substituters "..." \
  --option access-tokens "github.com=$(sudo cat /etc/nixos/.agent/config/token)"

# 看实时进度 (tail -f)
journalctl -u nix-rebuild --no-pager -f

# 看最近 N 行
journalctl -u nix-rebuild --no-pager -n 20

# 怎么看卡在哪:
#   building 'kernel/drivers/bluetooth/btmtk.o' → 在编内核
#   building 'nvidia-x11-580.142-7.0.9'       → 在编 NVIDIA 模块 (最慢)
#   linking kernel vmlinux                     → 快结束了
```

#### 方法 B: 直接在终端跑 (简单, 但会超时)
```bash
sudo .agent/config/rebuild.sh switch -v
```

#### 检查通用的进度指标
```bash
# 查当前 generation, 出现新 gen 即构建完毕
sudo nix-env -p /nix/var/nix/profiles/system --list-generations | tail -3

# 查看 build 日志 (构建已结束后)
nix log /nix/store/*-nixos-system-NixMEOW*.drv 2>/dev/null | tail

# 加速编译 (大包如 kernel/NVIDIA 模块时):
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
echo none | sudo tee /sys/block/nvme*/queue/scheduler
sudo sysctl -w vm.swappiness=10
sudo systemctl stop power-profiles-daemon
```

### 新增系统模块
```bash
mkdir -p modules/<category>/
# 编辑 modules/<category>/default.nix
# 在 modules/default.nix 添加 import (如未 import 整个目录)
```

### 新增用户模块
```bash
mkdir -p home/Reiky-REI/<name>/
# 编辑 home/Reiky-REI/<name>/default.nix (home-manager options)
# 在 home/Reiky-REI/default.nix 添加 import
```

### 排错命令
```bash
# 查看实际环境变量
cat /etc/environment
cat /etc/profiles/per-user/Reiky-REI/etc/profile.d/hm-session-vars.sh

# 查看系统级配置
nix-instantiate --eval -E '(import <nixpkgs/nixos> {}).config.environment.variables'

# 追踪模块来源
nixos-option <option.path>
```

## 7. 约定

- Nix 缩进: 2 空格
- 函数参数: `config, lib, pkgs, ...` (字母序)
- 目录入口: `default.nix`
- 模块命名: 小写 + 连字符，与 NixOS 选项名一致
- 系统层只管 NixOS options，home-manager options 放 home 层
- git commit 用中文描述
- 改动后先 `dry-activate`，通过再 `switch`

## 8. Session 日志

### 2026-05-24 — Home 重组 + 蓝牙修复

**分支**: `feat/home-reorg-bluez-binds`
**Commits**: `72c0edd`, `1f86ffb`, (待提交 btmtk 补丁)

**做了什么**:
1. Home 目录重组: 新结构 `desktop/apps/tools/editors/dev`
2. NVIDIA PRIME 卸载: RTX 4070 独显接入, `nvidia-offload` 调用
3. Hyprland submap: Super+Q → Q/Enter 确认, Esc/C 取消
4. Fcitx5: 左右 Shift 切换中英文
5. Clash: 从 XDG autostart 改为 WM 层启动 (niri + hyprland)
6. 蓝牙 MT7922: 诊断 `-22` 错误, 打内核补丁 `patches/btmtk-wmt-fix.patch`

**关键踩坑**:
- Niri 不支持 submap, 不要试图用 (26.04 及之前)
- home-manager 选项 (swaync/swayidle/polkit-gnome) 不能移到 NixOS modules
- fcitx5 NixOS module 的 settings 类型严格, 只接受预定义 key
- `linuxPackages_lts` 在 nixpkgs 25.11 不存在
- `kernelPatches` 导致内核全量重编 (~2 小时), 用 `systemd-run` 避超时
- 构建时需 `performance` governor 加速, 停 `power-profiles-daemon`
- 补丁文件需 `git add` 才能被 flake 识别

**待验证**: 蓝牙补丁内核重启后 `hciconfig hci0 UP`
