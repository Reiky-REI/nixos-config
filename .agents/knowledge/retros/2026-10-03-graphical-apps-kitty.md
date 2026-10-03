---
date: 2026-10-03
module: home/reiky/desktop/niri/sections/base.kdl, home/reiky/desktop/noctalia-settings.json
tags: [kitty, alacritty, yazi, neovide, niri, noctalia, graphics-protocol]
related: []
---

# 复盘: 图形需求应用从 alacritty 切到 kitty

## 结论

原则: **需要图形能力**的应用用 kitty（支持 graphics protocol / 图片预览）, 纯 TUI 保持 alacritty喵~

## 改动

`home/reiky/desktop/niri/sections/base.kdl`:
- `Mod+E` yazi: `alacritty -e yazi` → `kitty yazi`（yazi 图片预览依赖 kitty graphics protocol）喵~
- `Mod+N` 编辑器: `alacritty -e nvim` → 直接 `neovide`（GUI 版 nvim）喵~

`home/reiky/desktop/noctalia-settings.json`:
- `terminalCommand: "alacritty -e"` → `"kitty"`喵~

保持 alacritty 的: `Mod+Shift+O`(opencode) / `Mod+Shift+C`(claude) / `.agents/config/wake-agent.sh`
（纯 TUI 无图形需求）喵~

## 踩坑 / 要点

1. **kitty 没有 `-e`**喵~ alacritty 是 `-e cmd`, kitty 的语法是
   `kitty [options] [program-to-run ...]`（`--help`: "kitty --hold sh -c ..."）,
   所以 `alacritty -e yazi` → `kitty yazi`喵~
2. **noctalia terminalCommand 是字符串拼接**喵~ `Modules/Dock/DockContent.qml`:
   `terminalCommand.trim().split(" ").concat(app.command)`, 所以填 `"kitty"` 即可,
   写成 `"kitty -e"` 会被 kitty 当成未知参数报错喵~
3. **noctalia 设置走 `mergeJson` 激活, 手动 `hm-setup-env` 被中断会漏步骤**喵~ 本次激活多次被环境重启打断,
   `mergeNoctaliaSettings` 没跑到, 导致 `~/.config/noctalia/settings.json` 仍是旧值, 必须重跑激活喵~
   （`merge-json-activation.nix`: `deepmerge(target, source)`, source 覆盖 target 标量喵~）
4. **neovide 是独立 GUI 程序**, 不经过终端, 直接 `spawn "neovide"`喵~

## 验证

- `nixos-rebuild build` 通过
- 生成的 niri config: `niri validate` → `config is valid`; Mod+E/Mod+N 已是 kitty/neovide喵~
- 生成的 noctalia 模板 `terminalCommand` = `kitty`喵~
- 活配置: niri binds 已更新; noctalia live settings 需激活跑完 `mergeNoctaliaSettings` 后生效喵~
