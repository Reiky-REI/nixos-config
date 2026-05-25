# NixMEOW Agent Guide

## 快速命令
- dry-run: `sudo .agents/config/rebuild.sh`
- switch: `sudo .agents/config/rebuild.sh switch`
- 后台编译: `sudo systemd-run --unit=nix-rebuild ...` (详见 skill:rebuild)

## 知识体系
AI 工作纪律：
1. **instructions** 始终在 context: AGENTS.md + INDEX.md + conventions.md
2. 先读 **INDEX.md** → 按需读知识文件
3. 读 **INDEX.md** 中的 skill 清单 → 需要时加载 skill
4. 任务完成后写 **复盘** 到 retros/
5. 坑出现 2 次 → 提炼到 known-issues.md

## 常见陷阱
- swaync/swayidle/polkit-gnome 是 HM 选项，不是 NixOS 选项
- Niri 不支持 Hyprland 式 submap，用 `switch-to-named-submap`
- `linuxPackages_lts` 在 nixpkgs 25.11 不存在 (用 `linuxPackages_6_12`)
- nvidia-offload 调用独显: `nvidia-offload <command>`
