# 复盘 · 2026-08-16 GUI 会话异常与 AstrBot 自启

## 背景
gen 165 switch 后重启, 图形会话出现: 壁纸没了、nm-applet 没起、输入法快捷键短暂异常、屏幕白闪/壁纸层闪烁。

## 根因与修复
1. `swww` 包已改名为 `awww`, 二进制从 `swww-daemon` 改为 `awww-daemon`; niri startup 仍在用旧名 `swww-daemon`, 导致找不到二进制。
   - 修复: niri KDL 中迁移到 `awww-daemon`(但临时禁用, 见第 2 条)。
2. niri 26.04 layer-shell 背景层回归: 任何壁纸守护(swww/awww/mpvpaper)都会让壁纸层闪到最前, 60Hz 也复现。
   - 临时: 禁用壁纸守护, 桌面纯黑; 待 niri/awww 修复。
3. eDP-1 高刷白闪: 2560x1600@144/240 间歇白闪, 60Hz 也偶发一次(21:35:50, 无 kernel/DRM 日志)。
   - 临时: niri 配置锁 eDP-1 60Hz; 待查 amdgpu/niri。
4. `nm-applet` 未安装: hyprland/waybar 里的 `networkmanagerapplet` 包未导入 niri 环境。
   - 修复: 添加到 `modules/desktop/default.nix` 的 `environment.systemPackages`。
5. AstrBot 手动启动, 未开机自启。
   - 修复: 新增 `modules/services/astrabot.nix` 并启用 `services.astrabot.enable`。

## 验证
- 在 WorkSpace 克隆 `nixos-build-gui-fix` 中 `nixos-rebuild build` 成功:
  `/nix/store/82qsgj67kigp8pb0625mvrl8hc2lbar9-nixos-system-NixMEOW-26.05.20260806.445d861`
- 未直接 switch(遵守 NVIDIA PRIME 黑屏风险红线)。

## 待办
- 抓白闪 kernel 日志(发生时 `journalctl -b -0 -k --since '...'`)
- 查 niri 26.04 layer-shell 回归 issue, 恢复壁纸
- 确认 AstrBot 服务切换后 6185 正常
