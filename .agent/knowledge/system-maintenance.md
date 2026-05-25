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

| 路径 | 职责 | 放什么 |
|------|------|--------|
| `modules/common/` | 全局基础 | nix settings, timezone, i18n, fonts, zsh, sudo |
| `modules/hardware/` | 硬件策略 | microcode, GPU, bluetooth, intel-media-driver, firmware |
| `modules/desktop/` | 桌面基础 | hyprland/niri 系统启用, ly DM, xwayland, steam, fcitx5, 通知, idle |
| `modules/networking/` | 网络 | NetworkManager, 代理, 防火墙, SSH, clash |
| `modules/services/` | 系统服务 | pipewire, mpd, flatpak, CUPS, udisks2, timesyncd, 电源管理, polkit |
| `modules/development/` | 开发工具链 | wine, winetricks, CUDA |
| `home/Reiky-REI/desktop/` | WM 配置 + UI 组件 | compositors (hyprland/niri), launcher (rofi), wallpaper, noctalia |
| `home/Reiky-REI/apps/` | GUI 应用 | browser, communication, media, office |
| `home/Reiky-REI/tools/` | CLI 工具 | search, viewers, monitors, essentials |
| `home/Reiky-REI/editors/` | 编辑器/IDE | neovim, neovide, tmux, vscode, zed, lazygit |
| `home/Reiky-REI/dev/` | 开发语言 | nodejs, python, go, rust, gcc |
| `home/Reiky-REI/shell/` | shell 配置 | zsh + powerlevel10k |
| `home/Reiky-REI/terminal/` | 终端模拟器 | kitty, alacritty |
| `home/Reiky-REI/music/` | 音乐播放 | ncmpcpp, go-musicfox |
| `secrets/` | 加密密钥 | agenix 加密文件 |

## 3. 操作命令

### Rebuild
```bash
sudo .agent/config/rebuild.sh dry-activate   # 验证, 不切换
sudo .agent/config/rebuild.sh switch          # 切换
sudo .agent/config/rebuild.sh switch -v       # 编译进度可见
```

### 长时间编译 (kernel/NVIDIA 模块)
```bash
# systemd-run 后台跑, 不超时
sudo systemd-run --unit=nix-rebuild --same-dir --working-directory=/etc/nixos \
  --setenv=http_proxy=http://127.0.0.1:7897 \
  --setenv=https_proxy=http://127.0.0.1:7897 \
  --setenv=NIX_ACCESS_TOKEN="$(sudo cat /etc/nixos/.agent/config/token)" \
  nixos-rebuild switch --flake /etc/nixos#NixMEOW --print-build-logs

journalctl -u nix-rebuild -f   # 看实时进度
```

### 加速编译
```bash
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
echo none | sudo tee /sys/block/nvme*/queue/scheduler
sudo sysctl -w vm.swappiness=10
sudo systemctl stop power-profiles-daemon
```

## 4. 已知问题 & 注意事项

### 4.1 catppuccin 兼容性
`catppuccin` release-25.11 版本中**以下子模块不可用**，已全部注释：
- `catppuccin.{alacritty,bat,btop,cava,chromium,fuzzel,fzf,imv,lazygit,mpv,swaync,tmux}`
- 仅 `catppuccin.fcitx5` 可用

### 4.2 fcitx5 输入法
- 添加新输入法包时必须加 `fcitx5-gtk` 到 `i18n.inputMethod.fcitx5.addons`
- `waylandFrontend = true` 时 NixOS 模块不设 `GTK_IM_MODULE`，需手动在 `environment.sessionVariables` 设置
- XDG autostart 被禁用，由 niri `spawn-at-startup` 统一管理
- 切换快捷键: `Super+Space`; 左右 Shift 切换中英文

### 4.3 mpd.service 首次失败
- 首次 switch 后 `sudo killall mpd && sudo systemctl start mpd`

### 4.4 NVIDIA PRIME (RTX 4070 + AMD 核显)
- 默认使用 AMD 核显, 独显按需调用: `nvidia-offload <command>`
- `nvidiaBusId = "PCI:0:1:0:0"`, `amdgpuBusId = "PCI:0:6:0:0"`

### 4.5 Bluetooth MT7922
MediaTek MT7922 蓝牙 `hci0: Failed to send wmt func ctrl (-22)` 错误。
- **根因**: 内核 commit `634a4408c061` 严格校验 WMT 事件包长, MT7922 固件合法发短包
- **修复**: 打上游 commit `e3ac0d9f1a20` 等价补丁 (6.12.91+ / 7.1-rc1+)
- **当前**: `patches/btmtk-wmt-fix.patch` 已准备好, 需运行上方「长时间编译」命令后重启

### 4.6 已知HM/NixOS选项误判
- swaync, swayidle, polkit-gnome 是 **home-manager** 选项，不是 NixOS 选项
- fcitx5 NixOS module `settings` 类型严格，不接受未预定义的 key
- vim `settings.*` 在 HM 25.11 中多数 key 不支持，应移入 `extraConfig`
- `linuxPackages_lts` 在 nixpkgs 25.11 不存在 (改用 `linuxPackages_6_12` 或具体版本)

### 4.7 代理与网络
- 代理: `http://127.0.0.1:7897`
- GitHub token: `.agent/config/token` (gitignore 保护)
- 镜像: TUNA, USTC
