---
date: 2026-05-27
module: modules/virtualization/default.nix, .agents/knowledge/
tags: [waydroid, gbinder, aidl3, upgrade-plan]
related:
  - ../decisions/nixos-26.05-upgrade-plan.md
  - ../../known-issues.md
---

# 复盘: Waydroid gbinder aidl3 修复 + nixos-26.05 升级计划

## 改动

- `modules/virtualization/default.nix`: 添加 `environment.etc."gbinder.d/waydroid.conf"` 覆写，将 binder 协议从 NixOS 默认的 `aidl2` 改为 `aidl3`
- `.agents/knowledge/decisions/nixos-26.05-upgrade-plan.md`: 新建决策记录，记录 nixos-26.05 升级待办和等待条件
- `.agents/knowledge/INDEX.md`: 新增 `decisions/` 目录引用和决策索引表

## 问题

Waydroid 1.5.4 自动将 `waydroid.cfg` 的 `binder_protocol` 设为 `aidl3`（Lineage 20/Android 13），但 NixOS 25.11 的 `virtualisation/waydroid.nix` 模块硬编码了 `aidl2` 到 `/etc/gbinder.d/waydroid.conf`，导致 binder 协议不匹配 → `waydroidplatform` 服务无法通信。

## 解决

用 `lib.mkForce` 覆盖 NixOS 模块的 `environment.etc."gbinder.d/waydroid.conf"`，正确设为 aidl3。

## 遗留

- nixos-26.05 目前是 beta，等正式版后升级 flake.nix 的三个 input，详见 `decisions/nixos-26.05-upgrade-plan.md`
- 26.05 稳定后确认上游 gbinder 配置是否已修复 aidl3，若已修复可删除本覆写
