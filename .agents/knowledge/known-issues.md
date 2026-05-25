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

## NVIDIA PRIME (RTX 4070 + AMD 核显) ⚠️ switch 崩溃风险
- 默认使用 AMD 核显，独显按需调用: `nvidia-offload <command>`
- `nvidiaBusId = "PCI:0:1:0:0"`, `amdgpuBusId = "PCI:0:6:0:0"`
- **🚨 `nixos-rebuild switch` 严重风险**: 当 compositor (niri) 运行在 NVIDIA GPU 上时，switch 重启 `polkit.service` + `sysinit-reactivation.target` 会导致 niri 丢失 DRM master 权限 → 黑屏崩溃 → 必须硬重启
- **教训**: 内核变更或服务重启场景 **必须用 `build` + 手动 reboot**，绝不能直接 `switch`

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

## claude-code + DeepSeek 集成
- `claude-code` 包在 nixpkgs **stable** (25.11) 中有，在 **unstable** 中没有
- `programs.claude-code` HM 模块不存在（至少 release-25.11），应直接加 `home.packages`
- 安装: `home.packages = [ pkgs.claude-code ]`，主程序 `claude`
- **Claude Code 2.1.140 交互式 REPL 走 Anthropic bridge 做 session 验证**，直接连 DeepSeek `/anthropic` 端点会 "Not logged in"
- **解决方案**: 用 [cc-switch-cli](https://github.com/SaladDay/cc-switch-cli) 本地代理
  - `cc-switch` 安装到 `~/.local/bin/cc-switch`
  - `~/.claude/settings.json` 由 cc-switch 管理（含真实 API Key）
  - shell env 只设 `ANTHROPIC_BASE_URL=http://127.0.0.1:15721` + `ANTHROPIC_AUTH_TOKEN=proxy-placeholder`
  - `cc-switch proxy enable` 启动 daemon 在 15721 端口
- `ANTHROPIC_AUTH_TOKEN` 在 Claude Code 2.1.140 中被当作 OAuth token（`authMethod: oauth_token`），触发 bridge 验证
- `ANTHROPIC_API_KEY` 是 `authMethod: api_key`，不触发 bridge，但直接连 DeepSeek 仍因为 bridge 缺失而失败
- `claude --print` 非交互模式一直正常（不走 bridge）
- `cc-switch provider add` 是交互式（需 TTY），脚本化需 sqlite3 直接写库

## NixOS 常见误判
- swaync/swayidle/polkit-gnome 是 **home-manager** 选项，不是 NixOS 选项
- fcitx5 NixOS module `settings` 类型严格，不接受未预定义的 key
- vim `settings.*` 在 HM 25.11 中多数 key 不支持，应移入 `extraConfig`
- `linuxPackages_lts` 在 nixpkgs 25.11 不存在 (改用 `linuxPackages_6_12` 或具体版本)

## Nix import 路径 .nix 后缀
- Nix 的 `imports = [ ./path ]` **不会**自动补 `.nix` 后缀
- 若文件是 `foo.nix`，必须写 `./foo.nix`，不能只写 `./foo`

## Flake eval: import 的文件需先 git add
- flake eval/build 使用 git staging 中的源文件，未 `git add` 的新文件会报 `path does not exist`
- 在 flake output 中 import 新文件时，必须先 stage (`git add`) 再 eval

## linuxPackages_latest (kernel 7.0.9+) 缺少 ip_tables.ko
- `CONFIG_NETFILTER_XTABLES_LEGACY` 未开启 → 无 `ip_tables.ko`，`iptables-legacy` 不可用
- 需要 nftables 的应用 (如 Waydroid) 需 patch 改用 `nft` 命令
- Waydroid 修复方式: overlay 修补 `waydroid-net.sh`，设 `LXC_USE_NFT=true` + 添加 `nftables` 到 PATH

## 代理与网络
- 代理: `http://127.0.0.1:7897`
- GitHub token: `.agents/config/token` (gitignore 保护)
- 镜像: TUNA, USTC
