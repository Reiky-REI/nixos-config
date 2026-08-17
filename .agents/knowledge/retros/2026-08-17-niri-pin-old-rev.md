---
date: 2026-08-17
module: flake.nix + flake.lock
tags: [niri, noctalia, quickshell, flicker, nixpkgs-unstable, overlay]
layer: common
severity: high
related:
  - ../../known-issues.md (QSH/壁纸层闪烁 -> niri 回退旧 rev 方案)
  - ../requests/pending/2026-08-16-niri-amd-flicker.md (问题跟踪)
experience:
  - "nixpkgs 包版本号不变但 commit 变 (如 niri 26.04) 时, 出回归可用独立 input pin 旧 rev + overlay 只回退单包, 不动其他包"
  - "DSH 沙箱 /etc/nixos 只读 -> flake 改动借道 9502 root 通道; 大文件用 base64 分块 + diff -u 核对后 git apply"
  - "验证旧 rev 先翻 git 历史: git show <commit>^:flake.lock 提取该时点输入 rev 与 narHash, 不靠记忆"
---

# 复盘 · 2026-08-17 niri 回退旧 nixpkgs-unstable rev 修复 QSH/壁纸层闪烁

## 背景
QSH/壁纸层闪烁排查指向 nixpkgs-unstable 中的 niri 更新(8-07 d8080c8 起, 版本号 26.04 未变但 commit 变)喵~ 8-06 gen 161 (rev f83fc3c) 完全不闪喵~

## 变更
1. git 历史确认 d8080c8^ 的 flake.lock: nixpkgs-unstable rev = f83fc3c..., narHash sha256-cCO8aTqss5x... 喵~
2. flake.nix: 新增 `nixpkgs-unstable-old` 输入 pin 到 f83fc3c; outputs 解构加参; overlay 中 `niri = nixpkgs-unstable-old.legacyPackages.${system}.niri` 喵~
3. `nix flake lock --update-input nixpkgs-unstable-old` 录入旧 rev+narHash (仅新增一项, 其他输入未动) 喵~
4. `nixos-rebuild build --flake /etc/nixos#NixMEOW` build 验证喵~

## 未做 (红线)
- 不 switch: 等用户授权 喵~
- QSH settings wallpaper/nightLight 恢复 + 重启 QSH: switch 之后进行, 再让用户实测 喵~

## 待办
- switch 后恢复 QSH 设置 + 重启 QSH, 用户实测不闪且壁纸稳定 喵~
- 若仍闪: 查内核 7.1.6/amdgpu/mesa, 更新 pending request 喵~
