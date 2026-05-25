---
name: rebuild
description: NixOS rebuild 操作指引 — 标准构建、长时间编译、加速
---

## 标准命令
```bash
sudo .agents/config/rebuild.sh            # dry-activate（默认）
sudo .agents/config/rebuild.sh switch     # 切换
sudo .agents/config/rebuild.sh switch -v  # 显示编译日志
sudo .agents/config/rebuild.sh build      # 只构建不切换
```

## 长时间编译（内核/NVIDIA 模块）
```bash
# systemd-run 后台运行，不超时
sudo systemd-run --unit=nix-rebuild --same-dir --working-directory=/etc/nixos \
  --setenv=http_proxy=http://127.0.0.1:7897 \
  --setenv=https_proxy=http://127.0.0.1:7897 \
  --setenv=NIX_ACCESS_TOKEN="$(sudo cat /etc/nixos/.agents/config/token)" \
  nixos-rebuild switch --flake /etc/nixos#NixMEOW --print-build-logs

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
