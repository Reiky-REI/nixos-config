---
title: "26.05 升级断网事故修复完成 + gen 163 (7.1.6) 待重启验收"
requester: "NixMEOW/opencode"
date: "2026-08-16"
request_id: "2026-08-16-2605-wifi-fixed-pending-reboot"
priority: "high"
status: "done"               # pending → approved → done / rejected
---

## 申请内容

26.05 升级断网事故已修复完毕, 当前系统已在 gen 163 (26.05 + 内核 7.1.6) 喵~ 遗留唯一大事: **7.1.6 内核的 WiFi 表现未重启实测**喵~ 请 Claude Code 接手验收与后续处理喵~

## 为什么需要

8/16 凌晨 switch 到 26.05 默认内核 6.18.42 + 固件 20260605 组合下 mt7921e 与小米 AP 关联回归, WiFi 断网喵~ 已按用户决策升到内核 7.1.6 并 build+switch 到 gen 163 喵~ 但 gen 163 尚未重启, 7.1.6 是否修复关联回归未知喵~ 需要有人负责重启验收和后续跟踪喵~

## 具体方案

1. **重启验收 (用户主导)**: 重启默认进 gen 163 (loader default 已指 163) 喵~ 若 WiFi 正常 → 验收通过喵~ 若仍断网 → 在 boot 菜单手动选 gen 161 (25.11) 回滚喵~
2. **验收通过后**: upgrade/nixos-26.05 分支可考虑合 main 喵~ (该分支领先 main 8 提交, 含本次 c914b16) 喵~
3. **dsh agent-teams**: 已从 `~/.dsh/profiles/web/package.json` 的 `dependencies` + `bundles` 删除 `@nanmicoder/dsh-agent-teams` (上游 commit 缺构建产物 `lib/`) 喵~ 上游补产物后可加回喵~
4. **代理**: mihomo 由 clash-verge 托管在 `*:7897` 喵~ 若 opencode/nix/git 突然全断, 先查 `ss -tlnp | grep 7897` 喵~

## 预期影响

- gen 161/162 保留在 boot 菜单, 未删世代, 可随时回滚喵~
- hardware.nix 已钉 `linuxPackages_7_1`, 含注释喵~
- 提交在 upgrade 分支 (未合 main) 喵~

## 验证方式

- `uname -r` 应为 `7.1.6` 喵~
- `nmcli device status` / `iw dev wlp4s0 link` 确认 WiFi 关联喵~
- 三世代可回滚: `/boot/loader/entries/` 有 161/162/163 喵~

---

## 处理记录

| 日期 | 操作 | 说明 |
|------|------|------|
| 2026-08-16 | 提交 | `pending` → 等待重启验收 |
| 2026-08-18 | 取代 | 7.1.6 amdgpu 伪影回归实锤, 战役改钉 7.1.5 (nixpkgs-715 pin + mkForce), WiFi/蓝牙/背光验收全过 (见 retros/2026-08-18-kernel-715-flicker.md) |
| 2026-09-01 | 归档 | claude-code: 7.1.5 下多轮重启 WiFi 稳定 (含 9-1 当前 boot 关联正常), 本申请被 8-18 战役实质取代, `done` 归档喵~ |
| | 审批 | `approved` / `rejected` + 理由 |
| | 执行(build) | ✅ build gen 163 (26.05+7.1.6) 成功 |
| | 复盘 | `retros/2026-08-16-26.05-wifi-regression-half-switch.md` |
| | 归档 | `archive/` |

## 关联复盘
- `.agents/knowledge/retros/2026-08-16-26.05-wifi-regression-half-switch.md`
