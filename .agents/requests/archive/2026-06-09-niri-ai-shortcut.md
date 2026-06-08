---
title: "添加 niri AI 截图快捷键"
requester: "home/claude-code"
date: "2026-06-09"
request_id: "2026-06-09-niri-ai-shortcut"
priority: "medium"
status: "done"
---

## 申请内容

在 niri 配置中添加 AI 截图分析快捷键。

## 为什么需要

用户已安装 minl.ai AI 截图分析工具,需要绑定快捷键来触发截图功能。

## 具体方案

在 `~/.config/niri/config.kdl` 的 `binds {}` 部分添加:

```kdl
// AI 截图分析
Mod+Shift+A hotkey-overlay-title="AI 截图分析" { spawn "ai-screenshot"; }
```

建议添加位置: 在 `Mod+G hotkey-overlay-title="截图与录屏"` 那行后面。

## 预期影响

- 添加一个新的快捷键绑定
- 不影响现有功能
- 需要重新加载 niri 配置或重新登录

## 验证方式

```bash
# 1. 检查配置是否正确
grep "Mod+Shift+A" ~/.config/niri/config.kdl

# 2. 重新加载配置
niri msg action reload-config

# 3. 测试快捷键
# 按 Super+Shift+A
```

---

## 处理记录

| 日期 | 操作 | 说明 |
|------|------|------|
| 2026-06-09 | 提交 | `pending` → 等待审批 |
| 2026-06-09 | 处理完成 | 已添加到 `base.kdl` 第 48 行 |

## 关联复盘

- [复盘: 2026-06-09-niri-ai-shortcut](../knowledge/retros/2026-06-09-niri-ai-shortcut.md)
