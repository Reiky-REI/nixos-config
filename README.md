# NixOS 配置仓库 — NixMEOW

## 1. 仓库目标

管理个人 NixOS 系统的 declarative 配置，遵循分层清晰的模块化架构，降低耦合，便于维护。

## 2. 分层原则

```
flake.nix → hosts/MEOW/default.nix  → modules/{common,hardware,desktop,...}
                                     → home/{username}/
```

- **系统入口**：`flake.nix` 拼装输入输出 → `hosts/MEOW/default.nix` 作为 composition root
- **系统模块**：`modules/*` 存放 NixOS 系统级选项（daemon、kernel、硬件、桌面基础设施）
- **用户模块**：`home/{username}/` 存放 home-manager 用户级选项（应用、shell、editor、WM 配置）

## 3. 目录树

```
/etc/nixos/
├── config.nix                      # 用户配置中心 (username/fullName/githubHandle)
├── flake.nix                      # 入口：输入输出 + 系统实例
├── flake.lock                     # 锁定依赖版本
├── hardware-configuration.nix     # nixos-generate-config 生成，不动
├── hosts/
│   └── MEOW/
│       ├── default.nix            # Composition root (仅 imports)
│       └── hardware.nix           # Host-specific 硬件配置
├── modules/
│   ├── default.nix                # 聚合所有子模块
│   ├── common/                    # 全局基础设置
│   ├── hardware/                  # CPU/GPU/蓝牙/设备策略
│   ├── desktop/                   # 桌面会话栈 (NixOS 系统级选项)
│   ├── networking/                # 网络/代理/防火墙/SSH
│   ├── services/                  # 后台 daemon / 系统服务
│   ├── development/               # 开发工具链 (wine/CUDA 等)
│   ├── virtualization.nix         # Docker / libvirtd
│   └── documentation.nix          # man pages
├── home/
│   └── {username}/
│       ├── default.nix            # 用户态入口
│       ├── hyprland/              # Hyprland WM (home-manager)
│       ├── niri/                  # Niri WM (home-manager)
│       ├── rofi/                  # Rofi 启动器
│       ├── wallpaper/             # 壁纸
│       ├── noctalia/              # Noctalia shell
│       ├── music/                 # 音乐播放器
│       ├── shell/                 # Zsh / starship
│       ├── terminal/              # Kitty / Alacritty
│       └── programs/              # 应用 / 工具 / 开发环境
├── secrets/                       # 加密密钥 (agenix)
├── .agent/                        # AI 辅助工作目录
└── README.md
```

## 4. 各层职责

| 层 | 目录 | 放什么 | 不放什么 |
|----|------|--------|----------|
| 全局基础 | `modules/common/` | `nix.settings`, `nixpkgs.config`, `time`, `i18n`, `fonts`, `console`, `nix.gc`, `programs.zsh`, `security.sudo` | 桌面策略、硬件驱动、daemon |
| 硬件 | `modules/hardware/` | microcode、GPU 驱动、蓝牙、图形加速包 | 软件包、桌面、服务策略 |
| 桌面 | `modules/desktop/` | Hyprland/Niri 系统级启用、display manager、XWayland、Steam、Wayland env vars | 用户态 WM 配置、主题文件 |
| 网络 | `modules/networking/` | NetworkManager、代理、防火墙、SSH | 网络应用（浏览器等） |
| 服务 | `modules/services/` | PipeWire、MPD、Flatpak、CUPS、udisks2、电源管理 | 用户交互应用 |
| 开发 | `modules/development/` | wine、CUDA 工具链 | 编辑器配置（放 home） |
| 用户态 | `home/{username}/` | 应用、shell、编辑器、WM 配置文件、终端工具、GUI apps | 系统 daemon、内核参数 |

## 5. 职责边界

| 角色 | 职责 |
|------|------|
| **Host** (`hosts/MEOW/`) | 仅作 composition root：imports + host-specific 配置（用户定义、hostname、boot loader、stateVersion） |
| **Module** (`modules/*`) | NixOS 系统选项：daemon、kernel、hardware、系统能力、图形会话基础设施 |
| **Home** (`home/{username}/`) | home-manager 用户选项：应用、shell、editor、WM config、终端工具、用户偏好 |

### 系统层 vs Home 层

- **系统层 (NixOS modules)**：`services.mpd`, `services.pipewire`, `virtualisation.docker`, `services.openssh`, `services.flatpak`, `hardware.nvidia`, `programs.hyprland`, `services.displayManager`
- **Home 层 (home-manager)**：`programs.kitty`, `programs.rofi`, `programs.waybar`, `programs.wlogout`, `programs.zsh`（用户配置）, `programs.bat`, `programs.fzf`, home 文件部署

## 6. 如何新增一个系统模块

```bash
# 1. 创建模块目录
mkdir -p modules/<category>/<module-name>
touch modules/<category>/<module-name>/default.nix

# 2. 在 default.nix 中编写 NixOS 选项
# 3. 如果该模块需要被自动加载，在 modules/<category>/default.nix 中添加 import
# 4. 如果是独立模块，在 hosts/MEOW/default.nix 或 modules/default.nix 中添加 import
```

## 7. 如何新增一个 home module

> `{username}` 即 `config.nix` 中定义的 `username` 值，当前为 `Reiky-REI`。

```bash
# 1. 创建模块目录
mkdir -p home/{username}/<module-name>
touch home/{username}/<module-name>/default.nix

# 2. 在 default.nix 中编写 home-manager 选项
# 3. 在 home/{username}/default.nix 的 imports 中添加 ./<module-name>
```

## 8. 软件归类判断规则

| 类别 | 判断标准 | 示例 |
|------|----------|------|
| `services/` | daemon / 后台长期运行 | `openssh`, `flatpak`, `mpd`, `pipewire`, `docker` |
| `desktop/` | 图形会话入口 / Wayland 栈 | `programs.hyprland`, `programs.niri`, `displayManager`, `xwayland`, `swaync`, `swayidle` |
| `home/` | 用户交互应用 / 个人偏好 | `kitty`, `rofi`, `go-musicfox`, `waybar`, `wlogout`, `yazi`, `fastfetch`, `TERMINAL` |
| `hardware/` | 硬件驱动和微码 | NVIDIA 驱动, intel-media-driver, bluetooth, CPU microcode |
| `common/` | 全局基础设置 | timezone, locale, fonts, nix settings, sudo |
| `development/` | 系统级开发工具链 | wine, CUDA, 编译器 |

**环境变量归类**：
- `NIXOS_OZONE_WL` → `modules/desktop/`
- `QT_IM_MODULE` / `XMODIFIERS` → `modules/desktop/fcitx5/`
- `TERMINAL` → `home/{username}/`
- `XDG_DATA_DIRS` (flatpak) → `modules/services/`

## 9. Rebuild

```bash
# 使用 .agent/config/rebuild.sh (自动设置 proxy + GitHub token)
sudo .agents/config/rebuild.sh         # dry-activate (默认)
sudo .agents/config/rebuild.sh switch  # 实际切换

# 或手动执行
export NIX_ACCESS_TOKEN=ghp_...
sudo env \
  http_proxy=http://127.0.0.1:7897 \
  https_proxy=http://127.0.0.1:7897 \
  NIX_ACCESS_TOKEN="$NIX_ACCESS_TOKEN" \
  nixos-rebuild switch --flake /etc/nixos#NixMEOW
```

## 10. 排查配置归属错误

- 选项不存在 → 检查模块是否在正确的层（系统 vs home），以及是否被导入
- 选项冲突 → 在对应模块的 `default.nix` 中搜索该选项定义
- 行为不符合预期 → 检查 `hosts/MEOW/default.nix` 是否包含不应在 composition root 中的配置
- 找不到模块 → 检查 `modules/default.nix` 或 `home/{username}/default.nix` 的 imports
