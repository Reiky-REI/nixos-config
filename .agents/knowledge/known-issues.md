## WPS Office HiDPI (Wayland)

### 问题
WPS Office 在 Wayland + 高 DPI 屏幕上 UI 元素偏小。

### ⚠️ 重要教训
- **不要假设需要全局缩放** — 先问用户具体要放大什么
- **QT_SCALE_FACTOR 在 Wayland 下会撑爆窗口** — 高倍率导致窗口超出屏幕无法操作
- **WPS 内部有三个独立缩放系统** — 主 UI / 文档渲染 / 演讲备注互不影响
- **每次改完让用户测试** — 不要一次改太多再一起提交

### 已验证的方案
- `SlideShowPresenterNotesFontSize` 可单独调大演讲备注字体，不影响 UI
- `common\dpi` 只对主 UI 有效，文档渲染不认
- `ZoomOfFirstView` 只影响新建文档，不覆盖已打开文档

### 不推荐的方案
- ❌ `QT_SCALE_FACTOR >= 1.2` — 窗口超出屏幕
- ❌ `xdg.desktopEntries` — 不生成本地文件
- ❌ `writeShellScriptBin` + `home.packages` — 与同名包冲突
- ❌ `symlinkJoin` + `meta.priority` — home-manager 不尊重
