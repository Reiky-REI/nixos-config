---
date: 2026-05-27
module: home/Reiky-REI/desktop/niri/config.kdl
tags: [niri, focus-ring, transparent, opacity, overlay, electron]
related: []
---

# 排查: Niri focus-ring 粉色透过透明窗口

## 问题

当窗口设置 `opacity 0.6` 半透明时，聚焦窗口的粉色 focus-ring 会透过窗口内容显示出来，看起来像"整层粉色叠加在窗口后面"。

但该问题**仅出现在部分应用**（如 zed、vscode），不出现于其他应用（如 Alacritty、kitty）。

## 排查过程

### 已排除的假设

| 尝试 | 结果 | 结论 |
|------|------|------|
| focus-ring → border | 无效，且给非活跃窗口加了边框背景 | 两者都渲染在 content 之下 |
| `background-effect { xray true }` | 无效 | blur 不是粉色扩散的根因 |
| zed 去掉 `background-effect { blur }` | 无效 | blur 不是粉色扩散的根因 |

### 关键发现

**Alacritty 和 zed 命中的是同一个 niri window-rule**（`opacity 0.6`），但表现不一样：
- **Alacritty**：透过半透明只能看到桌面背景 + 4px 粉色边框
- **Zed/VSCode**：整层粉色透过

这说明粉色并非来自 focus-ring 的 4px 边框扩散，而是来自一个**完整的粉色矩形区域**渲染在窗口内容后面。

### 推测根因

Niri 渲染 focus-ring 时，可能在窗口背后绘制了一个**完整的粉色实心矩形**（用于实现圆角边框抗锯齿）。这个矩形在大多数应用（如 Alacritty）中被应用的**不透明 surface buffer** 完全遮挡；但在部分 Electron 应用（如 zed、vscode）中，由于 app 自身的 buffer 含有透明通道或未占满整个窗口区域，粉色矩形会透过显示。

简而言之：**应用端的 buffer 特性差异**决定了粉色是否可见，与 niri 配置无关。

## 现状

- focus-ring：保持开启（粉色 4px）
- border：关闭
- zed/vscode：`opacity 0.6` 无 blur（分开的 window-rule）
- 其他 app：`opacity 0.6` + blur

用户暂时搁置，等待更好的解决方案。
