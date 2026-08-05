# Known Issues

## MT7922 WiFi 长时间运行掉线 (mt7921e ASPM)

### 问题
长时间开机不关机后, WiFi 网卡掉线 (日志: `driver own failed`、`chip reset failed`、`Message timeout`)。

### 根因
- 网卡: MediaTek MT7922 (mt7921e 驱动), AMD 平台 ASPM 电源管理兼容性 bug
- 修复: `boot.extraModprobeConfig` 加 `options mt7921e disable_aspm=Y`
- ⚠️ 修复后重启才能生效 (`/sys/module/mt7921e/parameters/disable_aspm` 应显示 `Y`)

### 相关
蓝牙侧同样需要 `options btusb enable_autosuspend=0 reset=1` (已配置)

---

## 关机慢 / 黑屏关不死 / 风扇满速

### 问题
长时间运行后关机, 屏幕黑但关不死, 风扇满速, 耗时数分钟。

### 根因 (双元凶)
1. **nvme1 (SOLIDIGM 1TB, Windows NTFS 盘) 关机时 I/O 超时** × 7 次 × 30s
   - Windows 快速启动残留 (hiberfil.sys) + unsafe_shutdowns 64 次
   - 缓解: `DefaultTimeoutStopSec=30s`
2. **NVIDIA GSP 固件异常** (`Xid 120/154`) → GPU Reset Required → 黑屏+风扇满速
   - 暂观察, 未动配置

---

## 键盘背光 (COLORFIRE MEOW R16 = Clevo/Tongfang 模具)

### 问题
内置键盘背光只有蓝光, 无法调色; Linux 无标准 kbd_backlight 设备。

### 方案 (已验证编译)
- 该模具固件误报背光类型 0x26 → tuxedo_keyboard 不注册 LED
- 补丁版驱动: `pkgs/tuxedo-drivers-patched/` + `options tuxedo_keyboard force_clevo_kb_backlight_type=6`
- 加载后暴露 `/sys/class/leds/rgb:kbdlight` (亮度 + RGB 三通道)
- 控制工具: `kbdlight` (off/on/0-100/#rrggbb)
- overlay 要用 `linuxPackages.extend` 替换 (不是 nixpkgs 顶层 tuxedo-drivers!)

---

## NixOS 25.11 systemd 配置废弃

- `systemd.extraConfig` 报 "no longer has any effect; please remove it"
- 用 `systemd.settings.Manager.DefaultTimeoutStopSec` 替代

---

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

---

## U盘 sync/umount 卡住

### 问题
U盘复制大量文件后，执行 `sync` 或 `umount` 命令会卡住（内核日志显示 `task sync blocked for more than 491 seconds`）。

### 设备信息
- 设备：`/dev/sda` (VendorCo ProductCode, 250G, exfat)
- 分区：`sda1` (200M EFI), `sda2` (249.8G exfat 数据)
- USB ID：`usb-VendorCo_ProductCode_0103561133793794034`

### ⚠️ 核心教训
- **sync 会卡住** — 复制 2.2G 文件后执行 sync，内核阻塞超过 491 秒
- **umount 也会卡住** — 因为 sync 未完成，udisksctl/unmount 都会超时
- **懒卸载可以绕过** — `umount -l` 先断开挂载，后台完成 I/O

### 已验证方案
| 方案 | 结果 | 说明 |
|------|------|------|
| `sync && umount` | ❌ 卡住 | sync 阻塞导致 umount 也卡 |
| `udisksctl unmount` | ❌ 超时 | 同上 |
| `umount -l`（懒卸载） | ✅ 成功 | 先断开挂载，后台完成 I/O |
| `udisksctl power-off` | ✅ 成功 | 直接弹出设备（会自动 sync） |

### 避免方法
1. **复制完直接弹出**：`sudo udisksctl power-off -b /dev/sda`（会自动 sync）
2. **分批复制**：用 rsync 分批，避免一次性写入太多
3. **卡住用懒卸载**：`sudo umount -l /mnt/usb` 强制断开
4. **检查 Rust 缓存**：毕设项目有 1.9G target 目录，复制前可先清理
