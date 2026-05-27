---
date: 2026-05-27
module: home/Reiky-REI/desktop/niri/config.kdl
tags: [niri, focus-ring, transparent, opacity, blur, electron, zed]
related:
  - ../decisions/niri-focus-ring-transparent-overlay.md
---

# 复盘: Niri focus-ring 粉色透过透明窗口

## 问题

当 zed 等 Electron 应用设置 `opacity 0.6` 半透明后，focus-ring 的粉色会透过窗口内容显示，像"整层粉色叠加在后面"。Alacritty（同样 opacity 0.6）则无此问题。

## 排查

- focus-ring → border：无效，两者都在 content 之下
- `xray true`：无效
- 去掉 zed 的 blur：无效
- 关 focus-ring：粉色消失 ✅
- 关 focus-ring + zed 加回 blur + xray true：效果好 ✅

**结论**：问题是应用端差异，Alacritty 的 surface buffer 完全不透明遮挡了粉色矩形，Electron 应用则透出。

## 最终配置

```kdl
focus-ring { off }

// zed 单独规则（无 blur 会被移除，改为有 blur）
window-rule {
    match app-id="zed"
    match app-id="vscode"
    opacity 0.6
    background-effect {
      blur true
      xray true
    }
}

// 其他 app
window-rule {
    match app-id="Alacritty"
    match app-id="kitty"
    match app-id="steam"
    ...
    opacity 0.6
    background-effect {
      blur true
      xray true
    }
}
```

## 坑

- niri focus-ring 渲染在 content 之下，透明窗口必然透出
- Electron 应用（zed/vscode）比原生应用（Alacritty）更容易透出
- `xray true/false` 对粉色透过无影响
