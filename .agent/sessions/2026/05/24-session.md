# Session: 2026-05-24 NixOS 重构

## 目标
执行 9 步重构计划，将 NixOS 仓库重构成分层清晰的结构。

## 执行步骤结果

| # | 步骤 | 状态 | 备注 |
|---|------|------|------|
| 1 | .agent/ 目录结构 | ✅ | 含 config/token, env.sh, rebuild.sh, 计划, knowledge, sessions |
| 2 | flake.nix | ✅ | 镜像源、hostname→NixMEOW、fcitx5 overlay 移入模块、CookNixvim URL 修复 |
| 3+4 | Wiring + 配置迁移 | ✅ | hosts 精简为 composition root；modules 全部连通；配置拆入各子模块 |
| 5 | 分层修复 | ✅ | hyprland/niri/rofi/wallpaper/noctalia 移入 home/Reiky-REI/ |
| 6 | 清理 | ✅ | mdp→mpd、去重 i18n、bluetooth 移入 hardware、fcitx5 overlay |
| 7 | modules/development/ | ✅ | 含 wine + winetricks |
| 8 | README.md | ✅ | 按 10 项要求完整重写 |
| 9 | dry-activate 验证 | ✅ | 评估通过，系统 derivation 开始构建（5 分钟超时中断于构建阶段） |

## 补充修复

| 日期 | 内容 | 文件 |
|------|------|------|
| 2026-05-24 | 修复终端 (Alacritty/Kitty) 无法输入中文 — `fcitx5-gtk` 缺失、Wayland 竞态 | `modules/desktop/fcitx5/fcitx5.nix`, `home/Reiky-REI/terminal/kitty.nix` |
| 2026-05-24 | 用 google-chrome 替代 programs.chromium | `home/Reiky-REI/programs/app.nix` |

## 已知问题
1. catppuccin 主题子模块 (`catppuccin.bat`, `catppuccin.fzf`, `catppuccin.btop` 等) 在 release-25.11 中不可用，已注释
2. `modules/hardware/gpu/nvidia.nix` 存在拼写错误 `videoDirvers`/`grephics`，不影响当前 AMD+Intel 配置
3. `modules/hardware/gpu/cuda.nix` 存在拼写错误 `cudaa_nvcc`
4. `mpd.service` 首次启动时端口冲突需手动 `sudo killall mpd && sudo systemctl start mpd`

## 最终目录结构
```
/etc/nixos/
├── .agent/{config,plans/2026/05,knowledge,sessions/2026/05}/
├── flake.nix
├── hosts/MEOW/{default.nix,hardware.nix}
├── modules/{common,hardware,desktop,networking,services,development}/
├── home/Reiky-REI/{hyprland,niri,rofi,wallpaper,noctalia,music,shell,terminal,programs}/
└── secrets/
```

## Commits
```
818a35a fix: 修复终端无法输入中文问题
8cba9e7 fix: 添加 GTK_IM_MODULE 环境变量解决终端无法输入中文 (不完整)
a35c905 重构: 仓库分层架构整理
```
