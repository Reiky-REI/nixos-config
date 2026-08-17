---
date: 2026-08-18
module: flake.nix + flake.lock
tags: [kernel, amdgpu, niri, flicker, nixpkgs-715, hypothesis-falsified]
layer: common
severity: high
related:
  - ../../known-issues.md (QSH/壁纸层闪烁 → 内核 7.1.6)
  - ../requests/pending/2026-08-16-niri-amd-flicker.md (问题跟踪)
experience:
  - "niri 回退假设被证伪: 包 pin 治不了内核回归; 用 kernel.org 版本线与 kernels-org.json 的 bump 历史定位回归窗口"
  - "2026 年 nixpkgs 内核版本由 pkgs/os-specific/linux/kernel/kernels-org.json 驱动, 版本字面量不在 .nix 里"
  - "GitHub REST API 未认证限流 60/hr; 提交历史 HTML 页 (github.com/NixOS/nixpkgs/commits/<branch>/<path>) 不限流, 内嵌 react JSON 含 commit oid+message"
  - "btmtk-fix.nix 自带版本判定 (fixNeeded = versionOlder <6.12.93), 换内核线无需改蓝牙逻辑"
  - "pkill -f 会匹配执行通道自身 argv → 自伤; 杀进程用精确 pid/comm"
  - "DSH edit 工具对 /etc/nixos 仍 EROFS; flake 改动走 9502 root 通道 + perl/sed 原地编辑"
  - "往 modules 列表插新模块: 看清是 overlays 还是 modules 列表, 别插进 overlays"
  - "nix 命令在只读 HOME 下因 fetcher-cache 写失败; 用 XDG_CACHE_HOME 重定向到可写目录"
---
# 内核 7.1.6 amdgpu 伪影回归 → pin 7.1.5

## 结论
niri/QSH 均非根因; 内核 7.1.6 amdgpu 引入合成伪影(窗口表面间歇丢失/壁纸透上来), 回退 linuxPackages_7_1 到 7.1.5 (nixpkgs-715 = c578459) 喵~

## 待办
- [ ] nix flake lock 完成 + flake.lock 入库
- [ ] build + 用户授权 switch + 重启 (切内核必须重启)
- [ ] 验收: 窗口不透壁纸 / WiFi / 蓝牙 / 键盘背光 / 唤醒不黑屏
- [ ] 通过后撤 niri 回退 pin (nixpkgs-unstable-old) 并复盘 pin 策略
