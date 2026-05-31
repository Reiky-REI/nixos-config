---
date: 2026-05-31
module: hosts/MEOW/default.nix
tags: [boot, systemd-boot, 启动菜单]
layer: common
severity: low
related:
  - ../../known-issues.md
experience:
  - "configurationLimit 只影响启动菜单显示，不影响 nix store 中的 generation 数量"
  - "旧 generation 仍需通过 nix-collect-garbage + nixos-gc 清理"
---
