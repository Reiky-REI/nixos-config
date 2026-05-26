# 仓库架构

## 分层结构
```
config.nix (用户标识定义)
  → flake.nix (import 并通过 specialArgs 传递 username/fullName)
    → hosts/{hostname}/default.nix → modules/{common,hardware,desktop,...}
                                   → home/{username}/
```

## 各层职责
- **modules/common/** — 全局基础设置 (nix, nixpkgs, time, i18n, fonts, shell 等)
- **modules/hardware/** — CPU/GPU/蓝牙/音频设备相关策略
- **modules/desktop/** — Wayland/X11 会话栈、display manager、compositor、fcitx5、通知、空闲管理、xwayland-satellite
- **modules/networking/** — 网络、代理、防火墙、SSH、VPN、Clash
- **modules/services/** — 后台 daemon、系统能力服务 (管道/打印/MPD/Flatpak/polkit)
- **modules/development/** — 系统级开发工具链和平台支持
- **home/{username}/** — 用户态配置

## 用户配置中心
- `config.nix` — 仓库根目录，定义 `username`、`fullName`、`githubHandle`
- 所有用户标识符统一在此定义，其他地方通过 `specialArgs` 引用
- 变量传递路径: `config.nix → flake.nix specialArgs/extraSpecialArgs → NixOS/home-manager 模块`
- 新增用户: 改 `config.nix` 中的定义，`secrets/secrets.nix` 添加公钥，创建对应 `.age` 文件

## 分类决策规则
- daemon / 后台长期运行 → **services**
- 图形会话入口 / Wayland stack → **desktop**
- 用户交互应用 → **home**
- 硬件驱动和微码 → **hardware**
- 全局基础设置 → **common**

## 系统层 vs Home 层边界
- **系统层 (NixOS modules)**: daemon, kernel, hardware, 系统能力, 图形会话基础设施
- **Home 层 (home-manager)**: 用户应用, shell, editor, WM config, 终端工具, GUI apps, 用户偏好
