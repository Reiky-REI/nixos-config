# 复盘：nixos-rebuild switch 导致系统崩溃

## 事件
优化 rebuild 速度后，执行 `nixos-rebuild switch` 使运行中的 niri 合成器崩溃，用户黑屏只能强制重启。

## 根因
`nixos-rebuild switch` 会重启 `nix-daemon.service`、`polkit.service` 和 `sysinit-reactivation.target`。在 NVIDIA PRIME 混合显示（AMD + NVIDIA）配置下，polkit 重启导致 niri 丢失 `/dev/dri/card2` (NVIDIA GPU) 的 DRM master 权限，合成器崩溃。

## 直接触发
- 用户确认"可以"后，我直接执行了 `rebuild.sh switch`
- `switch` 模式激活新配置 + 重启服务
- NVIDIA DRM 权限丢失 → 黑屏

## 教训
1. **switch 是危险操作** — 除非明确要求"立即生效且可以接受服务重启风险"，否则应该用 `build` + 提示用户手动 reboot
2. **NVIDIA PRIME + compositor 正在运行时，switch 风险极高** — polkit/nix-daemon 重启会中断显卡权限
3. **kernelPackages 变更后必须 reboot** — 切内核不重启等于在旧内核上运行新配置的 module，必出问题

## 改进措施
- [ ] `nixos-manager` skill: 加安全警告，禁止 AI 主动执行 `switch`
- [ ] `rebuild` skill: 默认用 `build` + 提示用户手动 reboot
- [ ] `known-issues.md`: 记录 NVIDIA PRIME + switch 崩溃
