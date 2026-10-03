---
date: 2026-10-03
module: home/reiky/terminal/kitty.nix
tags: [kitty, cursor, home-manager, stash, wayland]
related: []
---

# 复盘: kitty 光标轨迹 + 闪烁配置

## 现象

用户反馈"在 `kitty.nix` 里改了光标, 终端却没展现"喵~

## 根因

1. **改动被 stash 遗忘** — 用户那次改动 (`cursor_trail 3` + `cursor_shape Hollow`) 存在于
   `stash@{0}` (message: `修改了kitty的光标`), 不在工作区喵~ Nix 读到的仍是注释掉的
   `# cursor_trail 3` 喵~ 当前激活的 `~/.config/kitty/kitty.conf` 自然没有这些设置喵~
2. **`cursor_shape Hollow` 是非法值** — kitty 0.47 的 `to_cursor_shape` 只接受
   `block` / `beam` / `underline` (见 `kitty/options/utils.py: cshapes`)喵~ `hollow` 只属于
   `cursor_shape_unfocused` (`cshapes_unfocused`)喵~ 非法值会被 kitty 忽略并报
   `Invalid cursor shape`喵~

## 改动

`home/reiky/terminal/kitty.nix` → `programs.kitty.extraConfig`:

```
# kitty 光标：轨迹动画 + 闪烁 + 失焦空心
cursor_trail 3
cursor_trail_color #cc7700
cursor_trail_decay 0.1 0.5
cursor_blink_interval 0.5
cursor_shape_unfocused hollow
```

- 删除非法的 `cursor_shape Hollow`; 按用户选择只保留失焦空心喵~
- 光标本身颜色不动, 继续由 Catppuccin-Mocha 主题提供喵~
- `cursor_blink_interval 0.5` 显式开启闪烁 (默认 `-1` = 跟随系统, 本机表现为不闪)喵~
- 未设 `cursor_stop_blinking_after`, 沿用默认 15s 无操作后停闪喵~
- 注意用户原话 `cursor_trail_secay` 是笔误, 正确选项是 `cursor_trail_decay`喵~

## 激活 (无需整机 switch)

本机 HM 集成在 NixOS module 中, 无 `home-manager` CLI喵~ 且整机 `switch` 有 NVIDIA PRIME
黑屏风险 (见 `rebuild.sh` 警告)喵~ 只需激活 HM 部分喵~ 方法: 直接调用 systemd 服务同款
wrapper 指向新 generation 喵~

```bash
/nix/store/<hash>-hm-setup-env /nix/store/<new-gen>-home-manager-generation
```

- 运行身份为 `reiky` (user), 只更新 `~/.config` 等 home 文件, 不动系统服务/DRM喵~
- kitty 常驻 `kitten __watch_conf__` 监视 `~/.config/kitty/kitty.conf`, 激活后自动重载,
  **无需重启 kitty** 喵~

## 验证

- `nixos-rebuild build` 通过 (HM 只重建 9 个 derivation)喵~
- 用 kitty 自带解析器对生成配置做无窗口校验喵~

```bash
kitty +runpy "from kitty.config import load_config; bad=[]; \
  o=load_config('/home/reiky/.config/kitty/kitty.conf', accumulate_bad_lines=bad); \
  print(bad, o.cursor_trail, o.cursor_trail_color, o.cursor_trail_decay, o.cursor_blink_interval, o.cursor_shape_unfocused)"
```

输出: `cursor_trail_color = Color(204, 119, 0)` (= #cc7700), `cursor_trail_decay = (0.1, 0.5)`,
`cursor_blink_interval = 0.5`, `cursor_shape_unfocused = 4` (HOLLOW), 我们的行无 bad line喵~

## 踩坑

1. **stash 会静默吞掉"已改但没生效"的改动** — 排障第一步应查 `git stash list`喵~
   "我明明改了" 的经典假象喵~
2. **`cursor_shape` vs `cursor_shape_unfocused`** — 前者不接受 `hollow`喵~ 别照搬网上/记忆里的值,
   本机源码 `kitty/options/utils.py` 才是准的喵~
3. **顺带发现两个既存无效选项** (未在本任务修复, 避免 scope creep):
   - `force_ltr_rendering` → `Ignoring unknown config key` (选项不存在)
   - `disable_ligature` → 应为 `disable_ligatures` (拼写, 报 `Ignoring invalid config line`)
   建议后续单独修喵~
