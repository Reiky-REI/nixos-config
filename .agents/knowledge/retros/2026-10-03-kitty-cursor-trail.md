---
date: 2026-10-03
module: home/reiky/terminal/kitty.nix
tags: [kitty, cursor, home-manager, stash, wayland, niri, keybind]
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

## 后续修订 (同日)

用户看过效果后追加三项:

1. **轨迹色 `#cc7700` → `#ffaa00`** — 用户说的"光标颜色"指的是**轨迹颜色**, 明确"光标颜色别改"喵~
   所以只改 `cursor_trail_color`, 光标本体色继续由主题提供 (主题值 `Color(245,224,220)`)喵~
2. **修掉两个既存无效选项**:
   - `force_ltr_rendering yes` → `force_ltr yes` (正确选项名, 无 `_rendering` 后缀)
   - `disable_ligature` → `disable_ligatures always` (正确名 + 必填值, 合法值 `never`/`cursor`/`always`)
3. **Niri 终端快捷键换成 kitty** — `home/reiky/desktop/niri/sections/base.kdl`:
   - `Mod+Return` → `spawn "kitty"`
   - `Mod+Shift+Return` → `spawn "kitty" "--class" "floating_terminal"`
     (kitty 的 `--class` 在 Wayland 设 app-id, 复用既有 `floating_terminal` window-rule 规则,
     不依赖 alacritty 特有行为)喵~

验证: kitty 解析 `BAD_LINES: []`; `niri validate` 输出 `config is valid`喵~

## 后续修订 2 (同日)

用户反馈"条状(beam)光标没有拖影", 遂决定改用块状光标并把轨迹色调成 `#ffbb77`喵~

`home/reiky/terminal/kitty.nix`:
- 新增 `cursor_shape block`
- `cursor_trail_color #ffaa00` → `#ffbb77`

**根因 (读 kitty 0.47.0 源码 `kitty/cursor_trail.c`)**:
- trail 只在光标"大跳"时触发喵~ `should_skip_cursor_trail_update()` 中, 当移动距离
  `abs(dx) + abs(dy) <= cursor_trail_start_threshold`（默认 `2`）时直接 return true 跳过喵~
  所以逐字符 / 单格移动永远不出拖影, 只有 **≥3 格** 的跳转才有喵~
- beam 的 trail 几何只有 `cursor_beam_thickness`（默认 `1.5pt`）那么宽
  (`update_cursor_trail_target()` 里 `right = left + dx/cell_w * cursor_beam_thickness`)喵~
  是一条极细的线, 视觉上几乎看不见; block 是整格矩形, 拖影非常明显喵~
- 结论: beam 不是"不支持"trail, 而是又细又只在跳格时触发, 观感上≈没有喵~
- 如果想让小范围移动也出拖影, 可调低 `cursor_trail_start_threshold`（如 `1`）喵~

验证: `cursor_shape=1(BLOCK)`, `cursor_trail_color=Color(255,187,119)`, `BAD_LINES: []`喵~

## 后续修订 3 (同日)

- 用户澄清: **要保留条状(beam)光标**, trail 看不到只是因为 `cursor_trail_start_threshold`
  默认 2 格、普通移动距离太近; 并非形状问题喵~
- 故**回退 `cursor_shape block`**, 新增 `cursor_trail_start_threshold 0`（0 = 任何移动都触发）喵~
- 轨迹色沿用 `#ffbb77`喵~

**重要发现 (为什么"条状光标"改不掉 / `cursor_shape` 被无视)**:
- HM 的 kitty 模块默认 `programs.kitty.shellIntegration.mode = "no-rc"`, 且
  `enableZshIntegration` 默认开喵~ 它会把 kitty 的 zsh 集成写进 `~/.zshrc`:
  先 `export KITTY_SHELL_INTEGRATION="no-rc"` 再加载 `kitty-integration`喵~
- kitty 的 zsh 集成在 `kitty-integration` 第 284 行: 只要 `no-cursor` 不在选项里, 就会
  **在每个提示符把光标切成 beam**喵~ 所以 `extraConfig` 里的 `cursor_shape` 会被它覆盖,
  改光标形状/想保留 beam 都必须从 `shellIntegration.mode` 入手喵~
- 想强制块状需 `programs.kitty.shellIntegration.mode = "no-cursor"`（HM 会自动补 `no-rc`,
  最终 `shell_integration no-rc no-cursor`）喵~ 本任务按用户意愿保留 beam, 故**没有**加喵~
- HM kitty 模块的 `xdg.configFile."kitty/kitty.conf".onChange` 会
  `pkill -USR1 -u $USER kitty` 触发重载; 但旧运行实例若未重载会一直用旧配置喵~
  排查"改了没生效"务必确认是不是**新起进程**, 否则会误判配置没落实喵~

验证: 活配置含 `cursor_trail_color #ffbb77` + `cursor_trail_start_threshold 0`, 无 `cursor_shape`,
`load_config` 返回 `Color(255,187,119)`、`threshold=0`、`BAD_LINES` 空喵~

## 踩坑

1. **stash 会静默吞掉"已改但没生效"的改动** — 排障第一步应查 `git stash list`喵~
   "我明明改了" 的经典假象喵~
2. **`cursor_shape` vs `cursor_shape_unfocused`** — 前者不接受 `hollow`喵~ 别照搬网上/记忆里的值,
   本机源码 `kitty/options/utils.py` 才是准的喵~
3. **`force_ltr` / `disable_ligatures` 的正确写法** — `force_ltr_rendering` 不存在 (应为 `force_ltr`);
   `disable_ligature` 缺了 s 且 `disable_ligatures` 必须带值 (`never`/`cursor`/`always`)喵~
   已在后续修订中修掉喵~
