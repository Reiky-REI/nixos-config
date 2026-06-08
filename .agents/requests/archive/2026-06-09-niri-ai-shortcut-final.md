---
title: "添加 niri AI 截图快捷键 (最终版)"
requester: "home/claude-code"
date: "2026-06-09"
request_id: "2026-06-09-niri-ai-shortcut-final"
priority: "high"
status: "done"
---

## 申请内容

在 niri 配置中添加 AI 截图分析快捷键 `Mod+Shift+A`。

## 为什么需要

用户已安装 AI 截图分析工具,需要绑定快捷键来触发功能。

## 具体方案

在 `~/.config/niri/config.kdl` 的 `binds {}` 部分添加:

```kdl
// AI 截图分析
Mod+Shift+A hotkey-overlay-title="AI 截图分析" { spawn "ai-screenshot"; }
```

建议添加位置: 在 `Mod+G hotkey-overlay-title="截图与录屏"` 那行后面。

---

## 处理记录

| 日期 | 操作 | 说明 |
|------|------|------|
| 2026-06-09 | 提交 | `pending` → 等待审批 |
| 2026-06-09 | 处理完成 | 重复申请 — 已通过 `88131b7` 在 `base.kdl:48` 添加 |

## 关联复盘

- 复盘: `2026-06-09-niri-ai-shortcut.md`
- 第一次申请: `2026-06-09-niri-ai-shortcut.md` (已处理)
- 第二次 dup: `2026-06-09-niri-ai-shortcut-hm.md` (已归档)
- 第三次 dup: `2026-06-09-niri-ai-shortcut-final.md` (本文件)
