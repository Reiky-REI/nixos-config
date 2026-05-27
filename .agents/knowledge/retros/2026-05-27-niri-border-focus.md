---
date: 2026-05-27
module: home/Reiky-REI/desktop/niri/config.kdl
tags: [niri, focus-ring, border, transparent]
related: []
---

# 复盘: Niri 焦点高亮 — focus-ring 改为 border

## 改动

`home/Reiky-REI/desktop/niri/config.kdl`:
- `focus-ring`: 设为 `off`（之前用 width 4 + 粉色内发光）
- `border`: 取消 `off`，active-color 改为 `"#fec5f5"`（沿用原粉色）

## 原因

Zed 等窗口设置 `opacity 0.6` 半透明后，原来 `focus-ring` 的粉色内发光会叠加在半透明窗口后面，视觉上很脏。改用 `border` 后高亮只表现为窗口外缘 4px 粉色边框，不影响半透明内容。
