---
date: 2026-06-08
module: home/Reiky-REI/desktop/hyprland/scripts/wallpaper-video.sh
tags: [wallpaper, multi-monitor, mpvpaper, swww, niri]
layer: home
severity: low
related:
  - ../../known-issues.md
experience:
  - "mpvpaper 硬编码输出名称会导致壁纸只显示在指定显示器上"
  - "动态检测显示器输出需要考虑不同 compositor (niri/sway) 的命令差异"
---

# 动态壁纸多显示器支持修复

## 问题
视频壁纸只显示在内建屏幕 (eDP-1) 上，外接屏幕 (HDMI-A-1) 没有壁纸。

## 根因
`wallpaper-video.sh` 和 `swww-rofi.sh` 中，mpvpaper 的输出被硬编码为 `eDP-1`：

```bash
# wallpaper-video.sh:17 (修改前)
mpvpaper eDP-1 "$VIDEO" --hwdec=vaapi-copy -o "--loop-file=inf --no-audio"

# swww-rofi.sh:53 (修改前)
setsid mpvpaper eDP-1 "$SELECTED" --hwdec=vaapi-copy -o "--loop-file=inf --no-audio --panscan=1.0"
```

## 修复方案
添加 `get_all_outputs()` 函数，动态获取所有活跃的显示器输出，为每个输出启动一个 mpvpaper 实例。

### 修改的文件
| 文件 | 修改内容 |
|------|---------|
| `wallpaper-video.sh` | 添加 `get_all_outputs()` 函数，修改 start 命令为每个输出启动 mpvpaper |
| `swww-rofi.sh` | 添加 `get_all_outputs()` 函数，修改视频壁纸部分为每个输出启动 mpvpaper |

### get_all_outputs() 函数实现
```bash
get_all_outputs() {
  if command -v niri >/dev/null 2>&1; then
    niri msg outputs 2>/dev/null | grep -oP 'Output "\K[^"]+' || echo "eDP-1"
  elif command -v swaymsg >/dev/null 2>&1; then
    swaymsg -t get_outputs 2>/dev/null | jq -r '.[].name' 2>/dev/null || echo "eDP-1"
  else
    echo "eDP-1"
  fi
}
```

## 验证
- 脚本语法检查通过
- nixos-rebuild build 构建成功
- 输出配置: `/nix/store/35m4m0dahsl637a3dc5qvxg4f562zncy-nixos-system-NixMEOW-25.11.20260518.687f05a`
