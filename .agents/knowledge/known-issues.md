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
- 补丁已就绪: `modules/hardware/bluetooth/patches/btmtk-wmt-fix.patch`

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

## Nix eval 性能：`nix flake check` 全量评估极慢

### 现象
`nix flake check`（即 `just check` 中的最终步骤）耗时 **2:30+**，远高于预期。
`nix eval .#nixosConfigurations.NixMEOW...` 纯评估耗时 **3:06**（171s user CPU）。

### 根因
1. **`checks.${system}.nixos` output**（QA 工具链 `e5dab66` 加入）定义为 `self.nixosConfigurations.NixMEOW.config.system.build.toplevel`，强制 `nix flake check` 完整评估整个系统配置
2. `nix flake check` 还会单独验证 `nixosConfigurations.NixMEOW` output，导致**全量评估执行两次**
3. 纯 eval 不走 daemon 的 eval cache，每次都是冷启动评估
4. 本 flake 含 2 个 nixpkgs inputs（stable + unstable）+ 5 个 flake inputs，模块数 153 个 `.nix` 文件，closure ~36GB / 24K paths

### 基准数据（2026-05-26）

| 命令 | 耗时 | 说明 |
|------|------|------|
| `nixos-rebuild build`（增量/无变更） | 7-8s | 正常，daemon eval cache 命中 |
| `nixos-rebuild build`（首次/冷） | 1:37 | 含 36GB substitute 下载，镜像 380MB/s |
| `nix flake check` | 2:30 | 两次全量 eval，无缓存 |
| `nix eval .#formatter.x86_64-linux` | 3s | 仅 formatter，快速 |
| `nix eval .#claudeConfig.settings` | 0.2s | 属性查找，极快 |
| `nix eval .#nixosConfigurations...toplevel.drvPath` | 3:06 | 全量评估，最慢 |

### 对策
- **`nix flake check` 预期 2-3 分钟**，日常验证不依赖它
- 日常验证用 `just rebuild`（即 `nixos-rebuild build`），增量仅 7-8s
- `just check` 中的 `nix flake check` 步骤只在提交前或 CI 中跑
- 若需加速 eval：考虑减少 flake inputs、模块拆分优化，但收益有限（Nix eval 是单线程的）
- `nixos-rebuild build` 走 daemon cache，始终是日常验证的首选命令

## 构建性能：资源瓶颈导致构建慢/失败

### 现象
- `nixos-rebuild build` 增量 **7-8s**（正常），但冷构建或涉及 unstable 包时极慢
- 上次后台 build 耗时 **20h+ CPU** 后因 `[Errno 2]` failed
- 构建期间系统卡顿、swap 使用攀升

### 根因
1. **磁盘空间危机**（首要原因）：`/nix/store` 分区 100G，已用 **88G (93%)**，仅剩 ~7G。Nix 构建需要临时空间，93% 意味着构建时频繁抢最后几 G 地盘
2. **内存过载**：14G RAM + `max-jobs = auto`（24路并行）→ 内存不足 → **swap 颠簸**（从 473MB 飙到 1.1G）→ I/O 爆炸
3. **479 个 system profile 残留**：大量旧 generation 和旧版本包被 GC root 锁住无法回收（3 个 rustc 版本 ~3GB、2 个 nvidia 驱动 ~1.8GB、2 个 clang/llvm ~2.8GB）
4. **GC 策略太保守**：每周运行一次，删 ≥7 天前 → 跟不上配置变更频率
5. **4 个 unstable 包无 binary cache**：niri / opencode / neovide / vscode 从 unstable 取，TUNA/USTC 不缓存 → 每次都本地编译

### 对策
- **紧急**：`nix store gc --delete-older-than 3d` + 删 stale `result` symlink
- **配置**：`max-jobs = 8` + `min-free = 5G` / `max-free = 10G` + GC 改为 daily / ≥3d
- **工作流**：日常验证用 `just rebuild`（7-8s），`just check` 只在提交前跑

<!-- 代理/网络配置见 skills/networking/SKILL.md -->
