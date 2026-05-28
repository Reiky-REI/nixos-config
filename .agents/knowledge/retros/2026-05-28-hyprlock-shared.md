---
date: 2026-05-28
module: home/Reiky-REI/desktop/{hyprlock,niri,hyprland}
tags: [锁屏, hyprlock, niri, noctalia, 模块重构]
layer: desktop
severity: low
related:
  - ../retros/2026-05-27-wallpaper-cleanup.md
---

# 锁屏方案：hyprlock 独立成共享模块

## 背景

Niri 会话的锁屏完全依赖 `noctalia-shell` IPC（`Super+L` → `noctalia-shell ipc call lockScreen lock`）。当 noctalia 桌面关闭时（crash/手动停止），锁屏不可用。

## 改动

1. **新建 `desktop/hyprlock/` 共享模块** — 从 `desktop/hyprland/hyprlock/` 抽取 `hyprlock.nix` 和 `hyprlock.conf`
2. **注册到 Niri 会话** — `desktop/default.nix` 加 `./hyprlock`
3. **从 Hyprland 会话移除** — `desktop/hyprland/default.nix` 去掉旧 import，删除原目录
4. **改 Niri `Super+L`** — 从 noctalia IPC 换成 `spawn "hyprlock"`，剪贴板和启动器仍走 noctalia IPC

## 文件清单

| 文件 | 变更 |
|------|------|
| `home/Reiky-REI/desktop/hyprlock/default.nix` | **新建** — hyprlock 模块 |
| `home/Reiky-REI/desktop/hyprlock/hyprlock.conf` | **移动** — 来自 hyprland/hyprlock/ |
| `home/Reiky-REI/desktop/default.nix` | +`./hyprlock` |
| `home/Reiky-REI/desktop/hyprland/default.nix` | −`./hyprlock/hyprlock.nix` |
| `home/Reiky-REI/desktop/hyprland/hyprlock/` | **删除** |
| `home/Reiky-REI/desktop/niri/config.kdl` | `Super+L` → hyprlock |

## 效果

- Noctalia 关闭后，`Super+L` 仍然可用（hyprlock 截图+模糊作为锁屏背景）
- 需 `nixos-rebuild switch` 生效 + 登出重登
