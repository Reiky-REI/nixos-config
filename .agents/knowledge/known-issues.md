# 已知问题 & 注意事项

## catppuccin 兼容性
catppuccin release-25.11 中以下子模块不可用，已全部注释：
- `catppuccin.{alacritty,bat,btop,cava,chromium,fuzzel,fzf,imv,lazygit,mpv,swaync,tmux}`
- 仅 `catppuccin.fcitx5` 可用

## fcitx5 输入法
- 添加新输入法包时必须加 `fcitx5-gtk` 到 `i18n.inputMethod.fcitx5.addons`
- `waylandFrontend = true` 时 NixOS 模块不设 `GTK_IM_MODULE`，需在 `environment.sessionVariables` 设置
- XDG autostart 被禁用，由 niri `spawn-at-startup` 统一管理
- 切换快捷键: `Super+Space`; 左右 Shift 切换中英文

## mpd.service 首次失败
- 首次 switch 后 `sudo killall mpd && sudo systemctl start mpd`

## NVIDIA PRIME (RTX 4070 + AMD 核显)
- 默认使用 AMD 核显，独显按需调用: `nvidia-offload <command>`
- `nvidiaBusId = "PCI:0:1:0:0"`, `amdgpuBusId = "PCI:0:6:0:0"`

## Bluetooth MT7922
- 现象: `hci0: Failed to send wmt func ctrl (-22)`
- 根因: 内核 commit `634a4408c061` 严格校验 WMT 事件包长
- 修复: 打上游 commit `e3ac0d9f1a20` 等价补丁 (6.12.91+ / 7.1-rc1+)
- 补丁已就绪: `patches/btmtk-wmt-fix.patch`

## Niri 配置
### keybind 属性名
- `mod` → 实际为 `modifier`
### submap 不支持
- Niri 不支持 Hyprland 式 submap
- 应用层实现: `switch-to-named-submap` + `switch-to-previous-submap`

## NixOS 常见误判
- swaync/swayidle/polkit-gnome 是 **home-manager** 选项，不是 NixOS 选项
- fcitx5 NixOS module `settings` 类型严格，不接受未预定义的 key
- vim `settings.*` 在 HM 25.11 中多数 key 不支持，应移入 `extraConfig`
- `linuxPackages_lts` 在 nixpkgs 25.11 不存在 (改用 `linuxPackages_6_12` 或具体版本)

## Flake eval: import 的文件需先 git add
- flake eval/build 使用 git staging 中的源文件，未 `git add` 的新文件会报 `path does not exist`
- 在 flake output 中 import 新文件时，必须先 stage (`git add`) 再 eval

## 代理与网络
- 代理: `http://127.0.0.1:7897`
- GitHub token: `.agents/config/token` (gitignore 保护)
- 镜像: TUNA, USTC
