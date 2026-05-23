# 仓库架构

## 分层结构
```
flake.nix → hosts/{hostname}/default.nix → modules/{common,hardware,desktop,...}
                                         → home/{username}/
```

## 各层职责
- **modules/common/** — 全局基础设置 (nix, nixpkgs, time, i18n, fonts, shell 等)
- **modules/hardware/** — CPU/GPU/蓝牙/音频设备相关策略
- **modules/desktop/** — Wayland/X11 会话栈、display manager、compositor (仅 NixOS 系统级选项)
- **modules/networking/** — 网络、代理、防火墙、SSH、VPN
- **modules/services/** — 后台 daemon、系统能力服务 (管道/打印/MPD/Flatpak)
- **modules/development/** — 系统级开发工具链和平台支持
- **home/{username}/** — 用户态配置 (shell/editor/apps/WM 配置/终端工具)

## 分类决策规则
- daemon / 后台长期运行 → **services**
- 图形会话入口 / Wayland stack → **desktop**
- 用户交互应用 → **home**
- 硬件驱动和微码 → **hardware**
- 全局基础设置 → **common**

## 系统层 vs Home 层边界
- **系统层 (NixOS modules)**: daemon, kernel, hardware, 系统能力, 图形会话基础设施
- **Home 层 (home-manager)**: 用户应用, shell, editor, WM config, 终端工具, GUI apps, 用户偏好

## Rebuild
```bash
# 一键 rebuild (推荐)
sudo .agent/config/rebuild.sh switch

# 或手动
export NIX_ACCESS_TOKEN=ghp_...
sudo env http_proxy=http://127.0.0.1:7897 https_proxy=http://127.0.0.1:7897 \
  NIX_ACCESS_TOKEN="$NIX_ACCESS_TOKEN" \
  nixos-rebuild switch --flake /etc/nixos#NixMEOW \
  --option substituters "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store https://mirrors.ustc.edu.cn/nix-channels/store https://cache.nixos.org" \
  --option access-tokens "github.com=${NIX_ACCESS_TOKEN}"
```
