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
| `modules/desktop/` | 桌面基础 | hyprland/niri 系统启用, ly DM, xwayland, steam, fcitx5 配置 | 用户态 WM 配置文件 |
| `modules/networking/` | 网络 | NetworkManager, 代理, 防火墙, SSH, clash | 浏览器, 应用 |
| `modules/services/` | 系统服务 | pipewire, mpd, flatpak, CUPS, udisks2, timesyncd, 电源管理 | 用户交互应用 |
| `modules/development/` | 开发工具链 | wine, winetricks, CUDA | 编辑器 (放 home) |
| `home/Reiky-REI/` | 用户态 | 应用, shell, WM 配置, 主题, 壁纸, 终端工具 | daemon, 内核参数 |
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
| Hyprland 用户配置 | `home/Reiky-REI/hyprland/` |
| Niri 配置 | `home/Reiky-REI/niri/` |
| Shell (zsh) | `home/Reiky-REI/shell/zsh.nix` |
| 终端 | `home/Reiky-REI/terminal/{kitty,alacritty}.nix` |
| 应用 | `home/Reiky-REI/programs/app.nix` |
| 开发工具 | `home/Reiky-REI/programs/development/dev.nix` |
| 主题 | `home/Reiky-REI/programs/tool.nix` (bat/fzf/btop/cava 被注释) |

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

### 5.4 拼写错误 (上游遗留)
- `modules/hardware/gpu/nvidia.nix`: `videoDirvers` (应为 `videoDrivers`), `grephics` (应为 `graphics`)
- `modules/hardware/gpu/cuda.nix`: `cudaa_nvcc` (应为 `cuda_nvcc`)

### 5.5 代理与网络
- 代理: `http://127.0.0.1:7897`
- GitHub token: `.agent/config/token` (gitignore 保护)
- 镜像: TUNA, USTC
- Rebuild 脚本: `.agent/config/rebuild.sh` 自动注入 proxy + token

## 6. 操作命令

### Rebuild
```bash
# 验证 (不切换)
sudo .agent/config/rebuild.sh dry-activate

# 切换
sudo .agent/config/rebuild.sh switch

# 手动
sudo env http_proxy=http://127.0.0.1:7897 https_proxy=http://127.0.0.1:7897 \
  NIX_ACCESS_TOKEN=$(cat .agent/config/token) \
  nixos-rebuild switch --flake /etc/nixos#NixMEOW \
  --option substituters "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store https://mirrors.ustc.edu.cn/nix-channels/store https://cache.nixos.org" \
  --option access-tokens "github.com=$(cat .agent/config/token)"
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
