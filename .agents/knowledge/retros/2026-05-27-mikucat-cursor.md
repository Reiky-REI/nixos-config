---
date: 2026-05-27
module: home/Reiky-REI/default.nix, home/Reiky-REI/desktop/niri/config.kdl
tags: [cursor, mukicat, niri, home-manager]
related: []
---

# 复盘: MikuCat 光标主题设置

## 改动

`home/Reiky-REI/default.nix`:
- 将 `home.pointerCursor` 从 Adwaita 切换到 MikuCat
- 使用 `pkgs.runCommand` 打包本地 `pkgs/cursors/MikuCat/` 目录
- 光标大小从 24px 调整为 32px

`home/Reiky-REI/desktop/niri/config.kdl`:
- 添加 `cursor { xcursor-theme "MikuCat"; xcursor-size 32 }` 配置

新增 `pkgs/cursors/MikuCat/`:
- 从 `~/Pictures/icons/MikuCat/` 复制，包含 92 个光标文件和 `index.theme`

## 原因

用户希望使用 MikuCat 光标主题替代默认的 Adwaita。

## 踩坑

1. **`stdenv.mkDerivation` 无法处理目录**: `src` 为目录时 unpackPhase 报错 "do not know how to unpack source archive"，改用 `pkgs.runCommand` 直接复制文件
2. **Flake 源路径限制**: 在 flake 内引用仓库外的绝对路径 (`/home/.../Pictures/icons/MikuCat`) 不可用，需要将文件复制到仓库内 (`pkgs/cursors/MikuCat/`) 并 `git add` 后才能被 flake 引用
