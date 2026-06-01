## WPS Office HiDPI (Wayland)

### 问题
WPS Office 在 Wayland + 高 DPI 屏幕上 UI 元素偏小。

### ⚠️ 核心教训（重要！）
- **所有 Nix 配置方案都失败了** — home.activation、xdg.desktopEntries、writeShellScriptBin、symlinkJoin 全部无效
- **只有直接改 Office.conf 才有用** — 用户手动修改 `SlideShowPresenterNotesFontSize=30` 生效
- **不要假设需要全局缩放** — 先问用户具体要放大什么
- **QT_SCALE_FACTOR 在 Wayland 下会撑爆窗口** — 高倍率导致窗口超出屏幕无法操作

### 失败方案清单
| 方案 | 结果 | 原因 |
|------|------|------|
| QT_SCALE_FACTOR=1.75 | ❌ 窗口太大 | Wayland 下窗口几何也被缩放 |
| QT_SCALE_FACTOR=1.25 | ❌ 还是太大 | 右边看不到 |
| QT_SCALE_FACTOR=1.1 | ❌ 注释变小 | UI 略大但文档内容反而小了 |
| common\dpi=144 | ❌ 只对主 UI 有效 | 文档渲染走独立管道 |
| ZoomOfFirstView=200 | ❌ 只影响新文档 | 已打开文档用自身 zoom |
| xdg.desktopEntries | ❌ 不生成文件 | home-manager 不可靠 |
| writeShellScriptBin | ❌ 包冲突 | 与同名包在 home.packages 中冲突 |
| symlinkJoin + meta.priority | ❌ 不生效 | home-manager 不尊重优先级 |

### 已验证方案
- ✅ `SlideShowPresenterNotesFontSize=30` — 用户手动改 Office.conf 生效
- ✅ 只放大演讲备注字体，不影响 UI

### 建议
对于 WPS 这类非标准 Qt 应用，直接改配置文件比 Nix 配置更可靠。
