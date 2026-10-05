---
date: 2026-10-05
module: modules/common/nix-prune.nix, modules/common/default.nix, .agents/config/rebuild.sh, justfile
tags: [nix-prune, generations, gc, rollback, boot-menu, systemd-boot, disk-space]
layer: system
severity: medium
related:
  - ../../known-issues.md
  - 2026-10-01-stage1-grub-os-selector.md
---

# 复盘: 世代一刀切导致 boot 菜单只剩一个世代 → 空间闸门式世代保留 (2026-10-05)

## 背景

用户发现 systemd-boot 菜单只列一条世代、条目无日期/代数喵。排查时间线:

- 10-04 16:43-16:44 `nixos-rebuild build/switch` 产生 generation 259
- **10-04 17:31** 磁盘吃紧处理时 (当时只剩 ~600M), agent (net) 代跑:
  `nix-env -p /nix/var/nix/profiles/system --delete-generations old` +
  `nix-collect-garbage -d` — 除当前外**全部**世代被清喵 (当时磁盘状态下的合理救火,
  且经用户确认; 问题不在这一次决策, 在**没有任何保底回滚点的机制**喵)
- 10-04 17:45 `nixos-rebuild switch` 把 boot 条目同步成与存活世代一致 → 菜单只剩一条
- 日常每日 00:00 `nix-gc` 原策略 `--delete-older-than 3d` 也在持续删回滚点

## 根因分析

1. **世代是回滚保单, 不是垃圾** — 正常积累的世代近乎零 store 成本 (闭包共享),
   只有磁盘临界时才值得清喵; 但原配置"每天删 3 天前"与事件里的"人工一刀切"两把刀
   并存, 回滚点始终单薄喵。
2. **清除不可恢复** — `nix-collect-garbage -d` 是真删除, 事后发现需要回滚为时已晚喵。
3. **删除入口分散** — GC options 与任意会话的手动命令都能删世代, 没有单一收口喵。

## 处置

按用户定稿策略「**空间够就不删, 空间不够才收口**」落地 `nix-prune-generations`:

- `nix.gc.options = ""` — 每日 GC 只做 store 回收, 不删世代 (`modules/common/default.nix`)
- 新模块 `modules/common/nix-prune.nix`: 空间闸门 (默认 15G) + 7d 全留 +
  7d 外保留最新 5 条, current 世代永不进删除集合, 默认 dry-run, `-y` 才执行喵
- `rebuild.sh switch/test/boot` 成功后自动跑 prune 预览; justfile 新增 `just switch` 喵
- 纪律固化: known-issues 顶部新增「世代清理纪律」(禁 `-d` / `--delete-generations old`),
  AGENTS.md / CLAUDE.md / README「世代保留策略」同步喵

## 效果

- 空间足够时世代积累再多也不删 (成本由 store 闭包共享吸收)喵
- 磁盘吃紧时按规则收口, 并始终保留最近 5 条窗口外回滚点喵
- boot 菜单保留世代多样性, 可读、可回滚; 一刀切路径被纪律禁止喵

## 后续

- [ ] 观察一次真实 GC (明日 00:00) 确认不再删世代
- [ ] 观察磁盘跌落 15G 时 prune 的删除清单行为 (可 dry-run 验证)
- [ ] 任务② (home-manager standalone 化, 后续会话) 的设计输入之一
