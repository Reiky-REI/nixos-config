# 复盘: 2026-05-27 限制构建 CPU 使用 + 工作流修正

## 背景
每次 `nixos-rebuild build` 跑满 CPU（24 核全占），导致 noctalia-shell 卡死无响应。

## 根因
`max-jobs = 8` 并行 + `cores = 0`（不限每构建核心数）→ 编译占满 CPU → Qt/QML 桌面 shell 分不到时间片 → 冻结。

## 变更

| 类型 | 文件 | 说明 |
|------|------|------|
| config | `modules/common/default.nix` | 加 `nix.settings.cores = 2`，每构建最多 2 核，8 路最多 16 核，留余量给桌面 |
| doc | `.agents/AGENTS.md` | Git 工作流第4步改为「写复盘」，确保复盘和代码同 commit，git 保持干净 |
| doc | `.agents/knowledge/conventions.md` | 新增「复盘先写再提交」规则 |

## 效果
未来 `nixos-rebuild build` 不会吃满全部 CPU，桌面（noctalia/niri）不受影响。
