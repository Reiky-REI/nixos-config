---
name: rebuild
description: NixOS rebuild 操作指引 — 标准构建、长时间编译、加速
agents: [opencode, claude]
---

## 🚨 安全第一规则

**此系统是 NVIDIA PRIME (AMD + NVIDIA) 混合显示，`switch` 有极高崩溃风险！**
`nixos-rebuild switch` 会重启 `polkit.service` 和 `sysinit-reactivation.target`，导致运行中的 compositor (niri) 丢失 NVIDIA DRM master 权限 → **黑屏，只能硬重启**。

**AI 工作流**:
1. **始终用 `build`** 替代 `switch`（除非用户明确要求立即切换并接受风险）
2. `build` 完成后，提示用户：
   - 若未变更内核 → 可执行 `sudo nixos-rebuild switch`
   - 若变更了内核 → 建议**重启系统**

## 标准命令
```bash
sudo .agents/config/rebuild.sh            # dry-activate（默认）
sudo .agents/config/rebuild.sh build      # ✅ 推荐：只构建不切换
sudo .agents/config/rebuild.sh switch     # ⚠️ 危险！NVIDIA 下合成器会崩
sudo .agents/config/rebuild.sh switch -v  # 显示编译日志
```

## 长时间编译（内核/NVIDIA 模块）
```bash
# systemd-run 后台运行，不超时
sudo systemd-run --unit=nix-rebuild --same-dir --working-directory=/etc/nixos \
  --setenv=http_proxy=http://127.0.0.1:7897 \
  --setenv=https_proxy=http://127.0.0.1:7897 \
  --setenv=NIX_ACCESS_TOKEN="$(sudo cat /etc/nixos/.agents/config/token)" \
  nixos-rebuild build --flake /etc/nixos#NixMEOW --print-build-logs

# 查看实时进度
journalctl -u nix-rebuild -f
```

## 加速编译
```bash
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
echo none | sudo tee /sys/block/nvme*/queue/scheduler
sudo sysctl -w vm.swappiness=10
sudo systemctl stop power-profiles-daemon
```
