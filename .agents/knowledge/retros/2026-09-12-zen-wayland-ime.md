---
date: 2026-09-12
module: flake.nix
tags: [zen, fcitx5, input-method, ime, wayland, gtk, catppuccin, 候选窗, theme]
layer: desktop
severity: low
related:
  - ../retros/2026-09-09-zen-browser-flash-ffmpeg.md (同一 Zen 打包链路)
  - ../retros/2026-05-24-home-reorg.md (fcitx5 环境变量来源)
  - ../../known-issues.md (Wayland 下 GTK 应用候选窗灰白 章节)
experience:
  - "fcitx5 的候选窗主题只在『fcitx5 自己画』时生效; 一旦候选窗由客户端自绘(fcitx5-gtk 的 client-side input panel), 就会退化成灰白默认样式 —— 判断谁在画看 fcitx5 DebugInfo 的 frontend: dbus 的 cap 带 ClientSideInputPanel 位, wayland_v2 不带喵~"
  - "GTK3 选输入法模块顺序(实测 gtk+3-3.24.52 源码 _gtk_im_module_get_default_context_id): 1. GTK_IM_MODULE 环境变量 → 2. GtkSettings gtk-im-module(settings.ini/XSETTINGS) → 3. 按 locale 自动选择(带 backend 过滤)喵~"
  - "只删 GTK_IM_MODULE 修不了: fcitx5-gtk 模块在 immodules.cache 里 default_locales=ja:ko:zh:*, zh_CN 在 locale 阶段命中 goodness 3, 而 wayland 模块 default_locales 为空(goodness 0), 永远自动选回 fcitx —— 必须显式 GTK_IM_MODULE=wayland, 这正是 fcitx5 维护者对 Firefox 的原话答案喵~"
  - "绝不要全局设 GTK_IM_MODULE=wayland: X11/XWayland 的 GTK 应用会去加载 im-wayland.so, 崩溃或丢 IME(上游 ghostty discussion #3628 实证); 正确做法是只给需要的程序包一层 wrapper 喵~"
  - "验证 GTK 输入法走哪条前端不用打字: 用临时 profile 起一个实例, 对比 fcitx5 DebugInfo 前后 IC 增删即可(新增 wayland_v2、无新增 dbus 即成功)喵~"
  - "在 /etc/nixos 里用 overlay + default.overrideAttrs { postFixup = wrapProgram ... } 能给上游包补环境变量, 无需改包的下游仓库(比跨仓改 Reiky-nixpkgs 更内聚)喵~"
---

# 复盘: Zen 浏览器候选窗灰白无主题 — 强制 GTK 走 Wayland text-input-v3

## 现象喵~

浏览器里打字时 fcitx5 候选窗能用，但样式是**灰白默认框**，没有 Catppuccin 皮肤；Alacritty / 其他程序一切正常喵~

## 根因喵~

fcitx5 本身的主题配置完全正常（`/etc/xdg/fcitx5/conf/classicui.conf` 指向 `catppuccin-mocha-mauve`，主题在 `fcitx5-with-addons` 包里且在 `XDG_DATA_DIRS` 中）喵~ 问题在**候选窗由谁绘制**喵~

fcitx5 维护者的机制说明喵：

> 在 Wayland 下，fcitx 不会用 Wayland 给 dbus frontend 的程序画界面，它只会选择 1、用 X 画，2、让程序自己画（fcitx5-qt / gtk）。

现场证据喵：
- **Alacritty** 的 IC 是 `frontend:wayland_v2`（text-input-v3）→ fcitx5 classicui 在 compositor 的 input-popup 上画 → **有主题** ✅
- **Zen** 的 IC 是 `frontend:dbus`（fcitx5-gtk im module），cap 带 ClientSideInputPanel → **GTK 客户端自绘** → 灰白默认 ❌

而 Zen 之所以走 dbus，是因为 `modules/desktop/fcitx5/fcitx5.nix` 全局设了 `GTK_IM_MODULE="fcitx"`（2026-05-24 commit 9d8ac65，当初为“终端无法输入中文”加的，但终端其实不吃这个变量）喵~

## 关键坑：只删 GTK_IM_MODULE 没用喵

读 gtk+3-3.24.52 源码 `_gtk_im_module_get_default_context_id()`，选模块顺序是喵：

1. `GTK_IM_MODULE` 环境变量
2. GtkSettings 的 `gtk-im-module`（settings.ini / XSETTINGS）
3. 按 locale 自动选择（带 backend 过滤）

系统 `immodules.cache` 里各模块的 `default_locales` 喵：

| 模块 | default_locales |
|------|-----------------|
| fcitx | `ja:ko:zh:*` |
| wayland | 空 |
| xim | `ko:ja:th:zh`（仅 X11） |

zh_CN 环境下 fcitx 在第 3 步命中 goodness 3，wayland 模块 goodness 0 —— 所以**删掉环境变量后 GTK 仍会 locale 自动选回 fcitx**，候选窗依旧灰白喵~ 必须**显式** `GTK_IM_MODULE=wayland`（fcitx5 维护者给 Firefox 的原话答案）喵~

## 为什么不能全局设喵

全局 `GTK_IM_MODULE=wayland` 会让 X11/XWayland 的 GTK 应用去加载 `im-wayland.so` → 崩溃或丢 IME（上游 ghostty discussion #3628 实证，Electron/VS Code 等 X11 应用会中招）喵~ 所以**只给 Zen 包一层**喵~

## 修复喵

`flake.nix` 的 Reiky-nixpkgs overlay 之后追加对 zen-browser 的 override（自包含，不动下游仓库）喵：

```nix
zen-browser = prev.zen-browser.overrideAttrs (old: {
  postFixup =
    (old.postFixup or "")
    + ''
      wrapProgram $out/bin/zen --set GTK_IM_MODULE wayland
    '';
});
```

## 验证喵

- build 产物 wrapper 确认含 `export GTK_IM_MODULE='wayland'` 喵~
- 用临时 profile 起独立实例，对比 fcitx5 `DebugInfo`：新增 **1 个 `frontend:wayland_v2`、0 个新增 dbus** → 证明 GTK 已改走 text-input-v3 喵~
- switch 成功，等重启 Zen 后打字确认候选窗变 Catppuccin 喵~

## 已知代价喵

niri + Firefox 在 text-input-v3 路径下有上游候选窗**闪烁** issue（niri #3099 / #4402），靠窗口边缘时可能闪，属已知喵~

## 遗留 / 可选喵

- 其他 Wayland GTK 应用仍会走 fcitx dbus 路径（灰白），因为它们没有像 Zen 这样单独包；若将来要统一，需另想 per-backend 方案（全局设会挂 X11）喵~
- 全局 `GTK_IM_MODULE="fcitx"` 本次**未动**（保持最小改动）喵~
