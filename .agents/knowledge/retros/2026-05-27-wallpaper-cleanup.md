---
date: 2026-05-27
module: wallpaper/mpvpaper/git-history
tags: [壁纸, mpvpaper, git, 瘦身, PRIME同步]
related:
  - ../../known-issues.md (NVIDIA PRIME卡死)
---

# 壁纸迁移 + mpvpaper + git 历史清洗

## 背景

桌面视觉层频繁卡死。根因定位为：
- noftalia-shell 的 `video-wallpaper` 插件通过 `video-wallpaper` 使用 NVIDIA NVDEC 硬解视频
- niri 合成器运行在 AMD 核显上（内屏 eDP-1 连接在 AMD）
- NVIDIA 解码的帧需通过 PRIME 同步复制到 AMD → 同步超时 → 视觉冻结
- 原本仅发生在 `nixos-rebuild build` 高负载时，逐渐恶化到空载也卡死

## 改动

### 1. 壁纸文件迁出 git 仓库

- 从 `home/Reiky-REI/desktop/wallpaper/image/` 迁移至 `~/Pictures/Wallpapers/static/`（26 张壁纸）
- 删除 nix 配置中 `home.file."config/wallpaper"` 部署部分（`swww.nix`）
- 更新 `swww-rofi.sh` 的 `WALLPAPER_DIR` 路径到 `~/Pictures/Wallpapers/static/`

### 2. 视频壁纸方案：mpvpaper + AMD VAAPI

- 新增 `wallpaper-video.sh` 控制脚本（支持 start/stop/toggle）
- 使用 AMD 核显的 VAAPI 硬解（`--hwdec=vaapi-copy`），完全绕开 NVIDIA
- 视频文件优先从 `~/Pictures/Wallpapers/videos/` 选，fallback 到 `~/download/`
- 关闭 noftalia 的 `video-wallpaper` 插件（`plugins.json`）

### 3. niri 快捷键

- `Mod+Shift+W` → 静态壁纸选择（rofi 菜单，已有）
- `Mod+Ctrl+W` → 切换静态/视频壁纸（新增）

### 4. git 历史清洗（待执行）

- 使用 `git filter-repo --path-glob` 删除所有 `*.png` `*.jpg` `*.gif` 等图片文件
- 当前 git pack 大小 34.36 MiB，历史含 28 个图片 blob
- 待 commit 完成后执行

## 文件清单

| 文件 | 变更 |
|------|------|
| `flake.nix` | +`pkgs-unstable.mpvpaper` |
| `home/Reiky-REI/desktop/wallpaper/swww.nix` | 删除 `home.file` 块 |
| `home/Reiky-REI/desktop/hyprland/scripts/swww-rofi.sh` | 改 `WALLPAPER_DIR` 路径 |
| `home/Reiky-REI/desktop/hyprland/scripts/wallpaper-video.sh` | **新建** |
| `home/Reiky-REI/desktop/hyprland/scripts/default.nix` | 注册 wallpaper-video.sh |
| `home/Reiky-REI/desktop/niri/config.kdl` | +`Mod+Ctrl+W` 快捷键 |
| `~/.config/noctalia/plugins.json` | `video-wallpaper` → disabled |
| `home/Reiky-REI/desktop/wallpaper/image/` | **删除**（26 个文件） |

## 新工作流

```bash
# 静态壁纸
~/.config/wallpaper/script/swww-rofi.sh        # rofi 选图

# 视频壁纸
~/.config/wallpaper/script/wallpaper-video.sh toggle   # 切换
~/.config/wallpaper/script/wallpaper-video.sh start    # 启动
~/.config/wallpaper/script/wallpaper-video.sh stop     # 停止

# 视频壁纸文件放这里
~/Pictures/Wallpapers/videos/

# 快捷键
Mod+Shift+W  # 选静态壁纸
Mod+Ctrl+W   # 切换静态/视频壁纸
```

## 后续

- 登出重登 niri 使配置生效（需用户操作）
- `git filter-repo` 清洗后需 force push + 通知其他协作者重新 clone
