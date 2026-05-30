# NixOS 配置仓库 — NixMEOW

## 1. 仓库目标

管理个人 NixOS 系统的 declarative 配置，遵循分层清晰的模块化架构，降低耦合，便于维护。
支持**多机器共享同一套配置**，通过硬件档位自动适配高低算力设备。

## 2. 分层原则

```
flake.nix → hosts/{HOST}/default.nix  → modules/{common,hardware,desktop,...}
                                         → home/{username}/
```

- **系统入口**：`flake.nix` 拼装输入输出 → `hosts/{HOST}/default.nix` 作为 composition root
- **系统模块**：`modules/*` 存放 NixOS 系统级选项（daemon、kernel、硬件、桌面基础设施）
- **用户模块**：`home/{username}/` 存放 home-manager 用户级选项（应用、shell、editor、WM 配置）

## 3. 目录树

```
/etc/nixos/
├── config.nix                      # 用户配置中心 (username/fullName/githubHandle)
├── machines.nix                    # 机器注册中心 (hostname → hardware profile)
├── flake.nix                       # 入口：输入输出 + 系统实例
├── flake.lock                      # 锁定依赖版本
├── justfile                        # 常用命令
├── opencode.json                   # OpenCode AI 配置
├── CLAUDE.md                       # Claude Code 工作指南
├── hosts/
│   └── MEOW/
│       ├── default.nix            # Composition root (仅 imports + host-specific)
│       ├── hardware.nix           # Host-specific 硬件策略（内核参数等）
│       └── hardware-configuration.nix  # nixos-generate-config 生成，不动
├── modules/
│   ├── default.nix                # 聚合所有子模块
│   ├── common/                    # 全局基础设置 + hardware profile
│   ├── hardware/                  # CPU/GPU/蓝牙/设备策略
│   ├── desktop/                   # 桌面会话栈 (Niri, Ly display manager, fcitx5)
│   ├── networking/                # 网络/代理/防火墙/SSH
│   ├── services/                  # 后台 daemon / 系统服务 (PipeWire, MPD, Flatpak)
│   ├── development/               # 开发工具链 (wine 等)
│   └── virtualization/            # Docker, libvirtd, Waydroid
├── home/
│   └── Reiky-REI/                 # 用户名与 config.nix 一致
│       ├── default.nix            # 用户态入口
│       ├── desktop/               # 桌面态配置 (niri, hyprland[legacy], hyprlock, rofi, wallpaper)
│       │   ├── niri/              # Niri WM — 主力 Wayland compositor
│       │   └── hyprland/          # Hyprland — 遗留配置（保留参考）
│       ├── shell/                 # Zsh
│       ├── terminal/              # Kitty / Alacritty
│       ├── editors/               # Neovim, VSCode, Zed 等
│       ├── apps/                  # 浏览器、社交、媒体、办公
│       ├── music/                 # 音乐播放器
│       └── tools/                 # 系统工具、搜索、查看器
├── lib/
│   ├── claude-config.nix          # Claude Code 配置生成
│   └── opencode-config.nix        # OpenCode 配置生成
├── pkgs/
│   └── cursors/                   # MikuCat 光标主题
├── secrets/                       # 加密密钥 (agenix)
├── .agents/                       # AI 辅助工作目录 (约定/复盘/知识库)
├── .claude/                       # Claude Code 项目配置
└── .opencode/                     # OpenCode 项目配置
```

## 4. 各层职责

| 层 | 目录 | 放什么 | 不放什么 |
|----|------|--------|----------|
| 全局基础 | `modules/common/` | `nix.settings`, `nixpkgs.config`, `time`, `i18n`, `fonts`, `nix.gc`, `programs.zsh`, `security.sudo`, `hardware.profile` | 桌面策略、硬件驱动、daemon |
| 硬件 | `modules/hardware/` | microcode、GPU 驱动、蓝牙、图形加速包 | 软件包、桌面、服务策略 |
| 桌面 | `modules/desktop/` | Niri 系统级启用、Ly display manager、XWayland、Steam、fcitx5、Wayland env vars | 用户态 WM 配置、主题文件 |
| 网络 | `modules/networking/` | NetworkManager、代理、防火墙、SSH | 网络应用（浏览器等） |
| 服务 | `modules/services/` | PipeWire、MPD、Flatpak、CUPS、udisks2、电源管理 | 用户交互应用 |
| 开发 | `modules/development/` | wine 等 | 编辑器配置（放 home） |
| 虚拟化 | `modules/virtualization/` | Docker、libvirtd、Waydroid | 容器内应用配置 |
| 用户态 | `home/{username}/` | 应用、shell、编辑器、WM 配置文件、终端工具 | 系统 daemon、内核参数 |

## 5. 职责边界

| 角色 | 职责 |
|------|------|
| **Host** (`hosts/{HOST}/`) | 仅作 composition root：imports + host-specific 配置（用户定义、hostname、boot loader、stateVersion） |
| **Module** (`modules/*`) | NixOS 系统选项：daemon、kernel、hardware、系统能力、图形会话基础设施 |
| **Home** (`home/{username}/`) | home-manager 用户选项：应用、shell、editor、WM config、终端工具、用户偏好 |

### 系统层 vs Home 层

- **系统层 (NixOS modules)**：`services.mpd`, `services.pipewire`, `virtualisation.docker`, `services.openssh`, `services.flatpak`, `hardware.nvidia`, `programs.niri`, `services.displayManager`
- **Home 层 (home-manager)**：`programs.kitty`, `programs.rofi`, `programs.waybar`, `programs.wlogout`, `programs.zsh`, `programs.bat`, `programs.fzf`, home 文件部署

## 6. 机器注册与硬件档位

本仓库支持多机器共享配置，通过 **machines.nix** 注册每台机器的硬件档位：

```nix
# machines.nix
{
  "NixMEOW" = { profile = "high"; note = "主力机 — RTX 4070"; };
  "NixPentium" = { profile = "low"; note = "老奔腾笔记本"; };
}
```

| 档位 | 视觉效果 | 自启服务 | 构建并行度 | 适用场景 |
|------|----------|---------|-----------|---------|
| `high` | blur + shadow + 半透明 + 动画 | waydroid, clash-verge, swww, wayvnc | 8 jobs | 独显或高性能集显 |
| `medium` | 轻度模糊 + 无阴影 | 无重型服务 | 4 jobs | 中端笔记本 |
| `low` | 无特效、无半透明 | 仅必需项 | 2 jobs | 老奔腾/赛扬/低端设备 |

### 添加新机器

```bash
# 1. 生成新机器的硬件配置
nixos-generate-config --root /mnt
# 得到 /mnt/etc/nixos/hardware-configuration.nix

# 2. 在 machines.nix 注册
echo '"NixPentium" = { profile = "low"; };' >> machines.nix

# 3. 创建主机配置目录
mkdir -p hosts/PENTIUM
cp hosts/MEOW/hardware-configuration.nix hosts/PENTIUM/
# 编辑 hosts/PENTIUM/default.nix（可参考 MEOW 的模板）

# 4. 在 flake.nix 添加 nixosConfigurations 条目
NixPentium = nixpkgs.lib.nixosSystem { ... modules = [ ./hosts/PENTIUM/default.nix ... ]; };

# 5. 构建
nixos-rebuild build --flake /etc/nixos#NixPentium
```

**注意**：未在 `machines.nix` 注册的 hostname 会直接 `abort` 报错退出，防止意外部署。

## 7. 如何新增一个系统模块

```bash
# 1. 创建模块目录
mkdir -p modules/<category>/<module-name>
touch modules/<category>/<module-name>/default.nix

# 2. 在 default.nix 中编写 NixOS 选项
# 3. 在 modules/<category>/default.nix 中添加 import
# （或如果你的模块是独立新分类，在 modules/default.nix 中添加）
```

## 8. 如何新增一个 home module

> `{username}` 即 `config.nix` 中定义的 `username` 值，当前为 `Reiky-REI`。

```bash
# 1. 创建模块目录
mkdir -p home/{username}/<module-name>
touch home/{username}/<module-name>/default.nix

# 2. 在 default.nix 中编写 home-manager 选项
# 3. 在 home/{username}/default.nix 的 imports 中添加 ./<module-name>
```

## 9. 软件归类判断规则

| 类别 | 判断标准 | 示例 |
|------|----------|------|
| `services/` | daemon / 后台长期运行 | `openssh`, `flatpak`, `mpd`, `pipewire`, `docker` |
| `desktop/` | 图形会话入口 / Wayland 栈 | `programs.niri`, `programs.hyprland`(legacy), `displayManager`, `xwayland`, `fcitx5` |
| `home/` | 用户交互应用 / 个人偏好 | `kitty`, `rofi`, `mpv`, `waybar`, `go-musicfox`, `yazi`, `fastfetch`, `TERMINAL` |
| `hardware/` | 硬件驱动和微码 | NVIDIA 驱动, intel-media-driver, bluetooth, CPU microcode |
| `common/` | 全局基础设置 | timezone, locale, fonts, nix settings, sudo, hardware profile |
| `development/` | 系统级开发工具链 | wine, 编译器 |

**环境变量归类**：
- `NIXOS_OZONE_WL` → `modules/desktop/`
- `QT_IM_MODULE` / `XMODIFIERS` → `modules/desktop/fcitx5/`
- `TERMINAL` → `home/{username}/`
- `XDG_DATA_DIRS` (flatpak) → `modules/services/`

## 10. Just 命令

```bash
just generate-opencode    # 生成 OpenCode 配置
just generate-claude      # 生成 Claude Code 配置
just generate-all         # 上面两个一起生成
just fmt                  # 格式化所有 nix 文件 (alejandra)
just check-fmt            # 预览格式化改动
just lint                 # 静态分析 (statix)
just check                # 完整验证：fmt check + lint + nix flake check
just rebuild              # 构建配置 (build 模式，不 switch)
just install-apk name url # 下载 APK 并安装到 Waydroid
```

## 11. Rebuild

```bash
# 使用 .agents/config/rebuild.sh (自动设置 proxy + GitHub token)
sudo .agents/config/rebuild.sh              # dry-activate (默认)
sudo .agents/config/rebuild.sh build        # 构建验证（推荐）
sudo .agents/config/rebuild.sh switch       # 实际切换（⚠️ NVIDIA PRIME 崩溃风险）

# 或手动执行
nixos-rebuild build --flake /etc/nixos#NixMEOW
```

> **⚠️ NVIDIA PRIME 系统**：`switch` 会重启 polkit → compositor 失去 DRM master → 黑屏。
> 日常验证用 `build` + 手动 `reboot`，避免直接 `switch`。

## 12. 排查配置归属错误

- 选项不存在 → 检查模块是否在正确的层（系统 vs home），以及是否被导入
- 选项冲突 → 在对应模块的 `default.nix` 中搜索该选项定义
- 行为不符合预期 → 检查 `hosts/{HOST}/default.nix` 是否包含不应在 composition root 中的配置
- 找不到模块 → 检查 `modules/default.nix` 或 `home/{username}/default.nix` 的 imports
