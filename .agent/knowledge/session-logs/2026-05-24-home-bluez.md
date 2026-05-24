# Session 复盘: Home 重组 + 蓝牙修复

## 元数据
- 日期: 2026-05-24
- 分支: `feat/home-reorg-bluez-binds`
- 涉及文件: ~100 changed
- 结果: 部分成功 (Home 重构 + NVIDIA + 快捷键 + Clash + Fcitx5 ✅; 蓝牙等待补丁内核重启验证)

## 做了什么

1. **Home 目录重组** — 新结构: desktop/apps/tools/editors/dev/shell/terminal/music
2. **NVIDIA PRIME 卸载** — RTX 4070 独显接入, 默认集显, `nvidia-offload` 按需调用
3. **快捷键统一** — Hyprland: Super+Q submap (Q/Enter 确认, Esc/C 取消); Niri: 保持 `Mod+Q` (Niri 26.04 不支持 submap)
4. **Fcitx5 输入法** — 左右 Shift 切换中英文
5. **Clash 自启** — 从 XDG autostart (GTK crash) 改为 WM 层启动 (niri + hyprland)
6. **蓝牙 MT7922** — 诊断出 `-22` 错误, 找到上游修复 commit, 打内核补丁

## Commits

| commit | 内容 |
|--------|------|
| `72c0edd` | feat: home重组 + NVIDIA PRIME + 内核6.12 + fcitx5 |
| `1f86ffb` | fix: clash WM层启动 + btusb参数 + niri修复 |
| (待提交) | fix: btmtk 内核补丁修复 MT7922 蓝牙 |

## 🔴 踩过的坑

| 错误 | 原因 | 修复 |
|------|------|------|
| Niri submap 搞崩全部 spawn-at-startup | Niri 26.04 不支持 submap, KDL 解析失败 → 回退默认配置 | 回退 `Mod+Q { close-window; }` |
| swaync/swayidle/polkit-gnome 移到 NixOS modules | 它们只是 home-manager 选项, NixOS 没有 | 回退到 home/default.nix |
| fcitx5 `"Behavior/OverrideEnabled"` 报不存在 | fcitx5 NixOS module 的 settings 类型严格 | 删除无效 key |
| `linuxPackages_lts` 不存在 | nixpkgs 25.11 移除了此属性 | 用 `linuxPackages_6_12` |
| `nodejs_23` 不存在 | 只有 nodejs_22 | 改为 `nodejs` |
| tmux `better-mousemode` 不存在 | nixpkgs 移除 | 删除该 plugin |
| vim `settings.clipboard`/`cursorcolumn` 不存在 | HM 25.11 严格类型 | 全部移入 `extraConfig` |
| `luajit` + `lua` 的 `luaconf.h` 冲突 | 两个包提供同文件 | 删 `luajit` |
| `softtabstop` 不在 HM 25.11 settings | 同上 | `set softtabstop=2` 在 extraConfig |
| 蓝牙 -22 反复出现 | 内核 commit 634a4408c061 对 MT7922 WMT 事件长度严格校验, 固件合法发短包 | 打上游 fix `e3ac0d9f1a20` 等价补丁 |

## 🟢 可复用经验

### Nix 构建
1. 新文件必须 `git add` 才能在 `nixos-rebuild` 中被识别
2. `dry-activate` 先跑, `switch` 后跑
3. `boot.kernelPackages = pkgs.linuxPackagesFor patchedKernel` — 内核补丁的最佳位置是 host 级 hardware.nix

### 配置验证
1. NixOS vs home-manager 选项不要混 (用 `find` 搜 nixpkgs/home-manager 源码)
2. Niri 配置用 `niri validate` 验证 KDL 语法
3. 内核编译选项读 `/proc/config.gz`
4. Fcitx5 NixOS 模块的 `settings` 类型严格, 不能随便加字段

### 硬件诊断
1. `hciconfig -a` + `sudo dmesg | grep hci0` 诊断蓝牙
2. `lsusb` / `lspci -D` 确认硬件型号
3. MediaTek BT 用 `btmtk.c`, Intel BT 用 `btintel.c` — 错误代码含义不同

### 行动准则
1. 先确认硬件型号再找 fix (不要假设芯片品牌)
2. 搜 Arch Wiki / kernel git log 找修复 commit
3. 补丁写完后在 hardware.nix 加注释 + TODO 删除条件
4. 每次 rebuild 后在 knowledge 里做记录

## ⚠️ 未解决问题
- 蓝牙补丁内核重启后需验证 `hciconfig hci0 UP`
- `linuxPackages_lts` 被 nixpkgs 25.11 移除, 之后的 kernel 选择策略需确认
- Clash-verge GTK autostart crash (已改 WM 层启动 workaround)
