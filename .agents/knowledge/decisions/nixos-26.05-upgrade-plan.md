---
date: 2026-05-27
module: flake.nix, modules/virtualization/default.nix
tags: [upgrade, nixos-26.05, waydroid, gbinder, niri]
related:
  - ../known-issues.md
  - ../retros/2026-05-27-waydroid-gbinder-aidl3.md
---

# 决策: nixos-26.05 升级计划

## 背景

当前系统运行在 `nixos-25.11`，`nixos-26.05` 分支已存在但尚未正式发布稳定版。
调查确认 26.05 的 niri 版本为 26.04，与当前 unstable 一致，不会降级。

同时，Waydroid 修复需要改 gbinder 配置，这个可以先行完成。

## 等待条件

nixos-26.05 正式版发布（去掉 beta 标签）。届时所有 flake input 一起升。

## 待办清单（等 26.05 正式版）

- [ ] `flake.nix`: `nixpkgs.url` 从 `nixos-25.11` 改为 `nixos-26.05`
- [ ] `flake.nix`: `catppuccin.url` 从 `release-25.11` 改为 `release-26.05`
- [ ] `flake.nix`: `home-manager.url` 从 `release-25.11` 改为 `release-26.05`
- [ ] 验证 niri 从 `pkgs-unstable` overlay 切回 `pkgs.niri` 没有降级（26.05 的 niri 已是 26.04）
- [ ] 如果以上验证通过，删除 `flake.nix` 中的 niri overlay：`(final: prev: { niri = pkgs-unstable.niri; })`

## 已完成的先行修复

- [x] `modules/virtualization/default.nix`: 添加 `environment.etc."gbinder.d/waydroid.conf"`，使用 `aidl3` 覆盖 NixOS 默认的 `aidl2` 配置，修复 binder 协议不匹配导致的 waydroidplatform 无法通信问题

## 关联坑

- `linuxPackages_latest` 缺少 `ip_tables.ko` 的问题在 26.05 中可能依然存在，Waydroid 的 nftables overlay 补丁需要保留 —— 详见 `known-issues.md`
- 升级前确认 26.05 的 NixOS waydroid 模块生成的 gbinder 配置是否修复了 aidl3（如果上游已修复则可删除本决策中的 `environment.etc` 覆写）
