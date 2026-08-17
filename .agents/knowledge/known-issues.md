# Known Issues

## 26.05 内核 6.18.42 + 固件 20260605: mt7921e 与小米 AP 关联回归 (2026-08-16)

### 问题
26.05 默认内核组合下 WiFi 连不上: 内核层能 associate 但链路掉, NM 反复 `association took too long` + 误判 `asking for new secrets` 喵~ `XIAOMI-周` 2.4G/5G 轮流失败约 8 分钟喵~

### 根因
- 内核 6.18.42 + WiFi 固件 20260605 组合与小米 AP 关联不稳 (8/5 的 ASPM 修复无关, gen 161/162 都有 `disable_aspm=Y` 且生效) 喵~
- 直连/api 测试: 换回 25.11 (内核 6.12.90) 立即恢复喵~

### 规避
- 钉内核: 26.05 无 `linuxPackages_lts`, 用 `boot.kernelPackages = pkgs.linuxPackages_6_12` 或升 `linuxPackages_7_1` 喵~
- 等上游修复 mt7921e 关联回归后换回默认喵~

### 验证
- `journalctl -b -1 -u NetworkManager` — 关联失败现场喵~
- `journalctl -b -1 -k | grep -iE 'mt7921|aspm|firmware'` — ASPM 生效 + 固件 Build Time 喵~

---

## switch 失败后必查 /boot/loader/loader.conf 默认代 (2026-08-16)

### 问题
`nixos-rebuild switch` 中途失败 (如 dsh-fence 抢端口 status=4) 会留下**半切换状态**喵: /run/current-system 已换新代, 但 loader default 也指向新代喵~ 重启直接进新代 (可能带回归) 喵~

### 规避
- 任何 switch 失败后: `sudo grep default /boot/loader/loader.conf` 喵~
- 回滚到旧代: `sudo /nix/var/nix/profiles/system-161-link/bin/switch-to-configuration switch` + `sudo nix-env -p /nix/var/nix/profiles/system --switch-generation 161` 喵~ (switch-to-configuration **不更新 profile 指针**) 喵~
- 回滚三验: current-system / profile / loader default 喵~

---

## dsh-fence 端口 3080 冲突 (2026-08-16 实锤)

### 问题
commit 158de0c 的警告成真喵: switch 时手动 dsh web 进程占用 3080 → dsh-fence 服务 EADDRINUSE → switch status=4/NOPERMISSION 半切换喵~

### 规避
- switch 前确认 3080 无手动进程: `ss -tlnp | grep 3080` 喵~
- dsh-fence 由 systemd 接管后, 不要再手动 `dsh web` 喵~

---

## systemd 服务默认 PATH 缺 /run/current-system/sw/bin → spawn bash ENOENT (2026-08-16)

### 问题
NixOS systemd 服务的默认 PATH 只有 coreutils/findutils/gnugrep/gnused/systemd 的 store bin喵, 不含 `/run/current-system/sw/bin` 喵~ 托管在 systemd 服务里的 agent/工具 (如 DSH dsh-fence) 用 `spawn("bash", ...)` 之类裸命令名会直接 ENOENT, 且文件类工具正常喵~ (不 spawn 进程所以不受影响) 喵~

### 规避
- 服务要跑用户级命令 → 用 `systemd.services.<name>.path = [ "/run/current-system/sw" ]` 喵~ (listOf [package str], 自动拼上默认基础包) 喵~
- 排查: 看 `/proc/<pid>/environ` 的 PATH 是否缺 `/run/current-system/sw/bin` 喵~

---

## 全局代理 mihomo 死亡 → opencode/nix/git 全断 (2026-08-16)

### 问题
clash-verge (mihomo) 退出后, 系统全局 proxy env (`networking.proxy` → `http://127.0.0.1:7897`) 仍生效喵, 所有经代理流量 (opencode API/nix/git) 全挂且无报错喵~

### 规避
- 排查先查代理活着没: `ss -tlnp | grep 7897` / `curl -m5 -o /dev/null -w '%{http_code}' http://127.0.0.1:7897` 喵~
- 拉起 mihomo: `nohup /nix/store/...-clash-verge-rev-2.4.7/bin/verge-mihomo -d ~/.local/share/io.github.clash-verge-rev.clash-verge-rev -f clash-verge.yaml` 喵~
- clash-verge 会自托管核心 (监听 `*:7897`) 喵~ `cache.db` 属主可能被 root 化, 需 chown 喵~

### 双开/控制器坑 (2026-08-16 实锤, 已加固 headless unit)
- headless unit 与 Clash Verge GUI 双开 → 抢 unix socket (`-ext-ctl-unix`) → `address already in use` 喵~
- 合并配置 `clash-verge.yaml` 里 `external-controller: ''` 被清空 (verge.yaml `enable_external_controller: false`) → 核心无 TCP 控制器喵~
- 解法 (已在 `home/Reiky-REI/tools/mihomo.nix` 落地):
  - unit 用 `-ext-ctl 127.0.0.1:9097` 强制 TCP 控制器, 弃用 unix socket 喵~
  - `ExecStartPre` 清理遗留 socket + 建 runtime 目录喵~
  - `StartLimitIntervalSec = 0` 放宽 crash-loop 限制 (双开抢端口时持续重试) 喵~
  - verge.yaml 补 `external-controller: 127.0.0.1:9097` + `enable_external_controller: true` 喵~
- 生效需 switch 后: 先 pkill 掉 GUI 核心, 再让 unit 接管 `*:7897` + `127.0.0.1:9097` 喵~

### 追加坑 (2026-08-16 实锤, switch 时踩到)
- **home-manager 多行块 ExecStartPre 会丢续行缩进**喵: 写成
  `ExecStartPre = ''\n  cmd1\n  cmd2\n''` 序列化后两行都顶到行首, systemd 把 `cmd2` 当成新键 → `expected entry key name but got '/'` → 激活失败喵~
  正确写法是列表: `ExecStartPre = [ "cmd1" "cmd2" ]` → 生成多条独立 `ExecStartPre=` 行喵~
- **root 残留的 runtime 目录/ socket**喵: `/run/user/1002/clash-verge-rev/` 曾被 root 进程 (clash-verge-service) 创建为 `root:root`, user unit 的 ExecStartPre `rm`/创建 socket 全部 `Permission denied` → 无限 crash-loop喵~ 一次性清理: `sudo rm -f /run/user/1002/clash-verge-rev/verge-mihomo.sock && sudo chown <user>:users /run/user/1002/clash-verge-rev` (在 /run, 重启即重置, 无需改配置) 喵~
- **pkill -f 会误杀自己的 shell**喵: 命令行里含关键字的 bash 进程会被 `pkill -f` 匹配杀掉导致命令挂死/超时喵~ 用括号技巧 `pkill -f '[v]erge'` 避免自匹配喵~

---

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

### ⚠️ 核心坑 1: DMI 兼容性检查 (2026-08-14 踩)
- tuxedo 驱动 `tuxedo_is_compatible()` 只匹配 DMI 厂商 "TUXEDO" 喵~ 
- 白牌 Clevo/Tongfang 模具 (COLORFIRE 等) 会 `-ENODEV` (journal: "Failed to insert module 'tuxedo_keyboard': No such device") 喵~ 
- 必须打补丁放行: `compat-check.patch` 在 `tuxedo_dmi_string_match` 加 `DMI_MATCH(DMI_SYS_VENDOR, "COLORFIRE")` 喵~ 
- 验证: 新模块 strings 应含 COLORFIRE 喵~ 

### ⚠️ 核心坑 2: kbdlight.nix 从未被 import (2026-08-14 踩)
- opencode 8/5 创建 `home/Reiky-REI/tools/kbdlight.nix` 但 `tools/default.nix` imports **漏了 `./kbdlight.nix`** 喵~ 
- 后果: kbdlight 命令/kbdlight-sync 服务/kbdlight-niri-off.sh 全部未生成 喵~ Mod+Shift+P 黑屏失效 喵~ 
- 教训: 写文件 ≠ 接线, 新增 home 模块必须检查 imports 喵~ 
- 验证: `nix eval .#nixosConfigurations.NixMEOW.config.home-manager.users.Reiky-REI.home.file` 应含 kbdlight 脚本 喵~ 

### ⚠️ 核心坑 3: ly 亮度键 acpid handler 不能用 seat0 判断 (2026-08-14 踩)
- `loginctl list-sessions | grep seat0` 在 ly 登录界面 (TTY) 也会匹配 喵~ (logind 给 tty1 挂 seat0)
- 正确判断: 遍历会话查 `Type=wayland/x11` + `Active=yes` 才跳过 喵~

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

---

## Clash Verge GTK 初始化失败 (Wayland)

### 问题
Clash Verge 启动时崩溃：`Failed to initialize gtk backend`。即使设置了 `serviceMode = true`，仍然尝试启动 GUI 组件。

### 根因
- Clash Verge 包 (`clash-verge-rev`) 启动时强制初始化 GTK 后端
- 在 Wayland 无头/服务模式下，GTK 初始化失败导致崩溃
- 与 `serviceMode = true` 配置无关，是包本身的问题

### 临时解决方案
- **手动启动**：`clash-verge &`（需要在有显示的环境下）
- **已禁用 autoStart**：`clash.nix` 中 `autoStart = false`

### 相关配置
- 文件：`modules/networking/clash.nix`
- 代理地址：`127.0.0.1:7897`
- 配置：`tunMode = true, serviceMode = true`

### 待解决
- 需要找到 headless 运行方案（如 clash-meta 或 mihomo）
- 或等待上游修复 GTK 依赖问题
## swww 已更名 awww, niri startup 需同步 (2026-08-16)

### 问题
nixpkgs 中 `swww` 包改名为 `awww`, 二进制从 `swww`/`swww-daemon` 改为 `awww`/`awww-daemon`。niri 配置仍 spawn `swww-daemon`, PATH 里没有该二进制, 壁纸不启动。

### 规避
- 新配置应写 `spawn-at-startup "awww-daemon"`。
- 旧脚本里的 `swww img` / `swww-daemon` 也要同步替换成 `awww img` / `awww-daemon`。

---

## niri 26.04 layer-shell 壁纸层闪到最前 (2026-08-16, 未解决)

### 问题
运行壁纸守护(swww/awww/mpvpaper)时, 壁纸层会间歇闪到所有窗口最前面, 60Hz 也复现。无 kernel/DRM 错误日志。

### 临时规避
- 停用壁纸守护, 桌面纯黑。
- 已写入 `requests/pending/2026-08-16-niri-amd-flicker.md` 跟踪。

---

## eDP-1 高刷白闪 (2026-08-16, 未解决)

### 问题
2560x1600@144/240 间歇白闪; 60Hz 偶发一次(21:35:50)。无 kernel/DRM 日志。

### 临时规避
- niri 配置锁 `output "eDP-1" { mode "2560x1600@60.000"; scale 1.5; }`。
- 待查 amdgpu/niri 后恢复高刷。

---

## AstrBot 开机自启 (2026-08-16)

### 问题
AstrBot 6185 之前手动启动, 重启后不自动运行。

### 修复
- 新增 `modules/services/astrabot.nix` 系统服务, `services.astrabot.enable = true`。
- DSH web 已由 dsh-fence 托管, 无需重复。

## 白闪元凶线索: Waydroid surfaceflinger 崩溃循环 (2026-08-16)

### 现象
白闪时间点(21:35:50, 21:55)与 waydroid 容器内 Android `surfaceflinger` 反复崩溃重启高度重合; `waydroid session stop` 后崩溃噪声消失。

### 临时规避
- niri 启动项临时注释 `waydroid session start`, 停用 Waydroid 自启, 等 Waydroid 图形栈修复。
- 需要使用时手动 `waydroid session start`。

## 睡眠(Suspend)唤醒后黑屏, 只能强制重启 (2026-08-17 实锤)

### 问题
系统 10:03 进入 Suspend 后, 屏幕黑屏无法唤醒, 只能长按电源强制重启。重启后一切正常 (niri/ly/背光/eDP 全部恢复)。

### 现场
- 上 boot: journalctl -b -1 | grep -iE 'Sleep|Suspend' → The system will suspend now! + Starting System Suspend... 后无唤醒日志
- 当前 boot: journalctl -b -0 -k | grep -iE 'gpu|Xid' 无 Xid/GPU 错误
- 睡眠前 niri 日志: locking session (09:44)

### 规避
- 长按电源强制重启 (唯一有效)
- 若频繁复现: 考虑 systemd.sleep.settings.Sleep.AllowSuspend = no 禁睡眠
- 屏幕黑不代表系统死, DSH/AstrBot 服务可能仍活着 (本事件 DSH 会话重启后被持久化恢复)

### 相关
- NVIDIA GSP 固件异常 (Xid 120/154) 关机黑屏问题同族


## QSH/壁纸层闪烁 → 内核 7.1.6 amdgpu 已知伪影回归 (2026-08-18, 7.1.5 pin 已就绪待 switch)

### 现象
- 普通窗口(Chrome/alacritty, 非全屏)内容间歇消失露出壁纸层, 有节奏连续闪且静止也闪; QSH 组件不闪; 全屏不闪 喵~
- 同族事件: 睡醒(挂起恢复)后黑屏无响应需强制重启; 关闭会话瞬间 niri 报 `Page flip commit failed ... (Permission denied)` 喵~

### 排查记录 (假设证伪链)
1. ~~QSH 壁纸/nightLight 触发~~ → 只关 nightLight 仍高频闪 (2026-08-18 实测), 证伪 喵~
2. ~~niri 回退旧 nixpkgs-unstable rev (f83fc3c, cg87spyg)~~ → **证伪**: gen 174 起多世代实测均同样闪 喵~
3. PSR/VRR 排除: eDP-1 面板不支持 PSR (PSR support 0); niri vrr disabled 喵~
4. **根因: 内核 7.1.6 amdgpu 伪影回归** — 社区同批报告 (Fedora discussion 198522 / openSUSE forums 195365 / lemmy 51201878), 特指 niri 下窗口操作/播放产生伪影, 与本机症状一致 喵~

### 方案 (2026-08-18, build 待过, switch 待授权)
- flake 新增输入 `nixpkgs-715` pin 到 `c5784590f98b42b4548d932005e365b4584c6be7` (2026-07-30, kernels-org.json = 7.1.5) 喵~
- `kernelPackages715 = (pkgs-715.linuxPackages_7_1).extend (tuxedo-drivers 补丁)`; 模块 `boot.kernelPackages = lib.mkForce kernelPackages715` 覆盖 hardware.nix 喵~
- 切内核必须重启才生效 (retro 2026-05-26-rebuild-crash) 喵~
- 回滚: 删 nixpkgs-715 输入 + 删 kernelPackages715 模块 → 回 hardware.nix 默认 7.1.6 喵~
- 备选 6.12 LTS: 26.05 pin 内 = 6.12.101/103 (≥6.12.93, btmtk 上游修复, 8/6 不闪同族) 喵~

### 验收清单 (switch+重启后)
- [ ] 非全屏窗口不再透壁纸 喵~
- [ ] WiFi (mt7921e/XIAOMI-周) 关联稳定 喵~
- [ ] 蓝牙 MT7922 不掉 喵~
- [ ] 键盘背光正常 (tuxedo 补丁驱动) 喵~
- [ ] 挂起唤醒不黑屏 喵~

### 保留项
- niri 回退 pin (nixpkgs-unstable-old) 暂保留作对照, 内核确认后再撤 喵~
