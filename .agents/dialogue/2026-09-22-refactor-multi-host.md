---
title: refactor/multi-host — 机器标签体系与 mkHost 生成器
date: 2026-09-22
status: 实施中 (Phase 1-2 完成, WSL 验证通过)
tags: [nixos, refactor, multi-host, machines, wsl, architecture]
---

# 机器标签体系 + mkHost 生成器 — 架构决策记录

## 1. 动机

旧结构的三个痛点喵:

| 痛点 | 具体表现 |
|------|---------|
| 无法多机部署 | `machines.nix` 只有性能档一个维度; `modules/` 无条件全量 import, 每台机吃同一套 (WSL 也会吃 ly/xserver/acpid/背光) |
| 硬编码到处飞 | `modules/hardware` 写死 intel microcode + intel-media-driver (实机是 AMD); `flake.nix` 内联大量 NixMEOW 专属模块 (nvidia/内核 pin/tuxedo/agenix) |
| 加机器成本高 | 要改 flake.nix 手写 `nixosConfigurations` 条目 + 复制模块列表 |

## 2. 决策

1. **标签体系 `meow.*`** (`modules/common/options.nix`):
   - `meow.kind`: laptop / desktop / wsl / vm
   - `meow.features`: 特性标签列表 (来自 machines.nix)
   - `meow.enabled`: features 派生的 attrset, 模块用 `(config.meow.enabled ? "<tag>")` 判断
   - `meow.isWSL`: kind 派生只读 bool
2. **模块自我屏蔽**: 宿主不再挑模块; `hosts/<hostname>/default.nix` 无脑 import `../../modules`,
   各模块自己 `lib.mkIf (config.meow.enabled ? "tag")` 决定生效与否。
   **加一台机器 = machines.nix 注册一行 + hosts/<hostname>/ 一个目录, flake 不用动。**
3. **mkHost 生成器** (`lib/mkHost.nix`): flake 的内联模块全部搬入,
   `nixosConfigurations = builtins.mapAttrs mkHost (import ./machines.nix)` 由注册表直接生成。
4. **flake 级特性**: `kernel-715` / `agenix-secrets` 两个标签在 mkHost 内用
   `builtins.elem` 判断 (mkIf 不能包 lambda 模块 —— 踩过的坑, 见 §5)。
5. **hosts 目录名 = 主机名**: `hosts/MEOW` → `hosts/NixMEOW` (与 machines.nix key 一致)。

## 3. 可用特性标签 (改标签时对照)

| 域 | 标签 |
|----|------|
| hardware | `bluetooth` `gpu-nvidia` |
| desktop | `compositor-niri` `display-manager-ly` `fcitx5` `tablet` `backlight` |
| networking | `networkmanager` `clash` `tailscale` |
| services | `dsh-fence` `llama-cpp` `opencode-root` `mcp-agents-bridge` `netease-cdn-bypass` `media-mpd` `audio` `flatpak` `printing` `libinput` `power` `udisks2` `suspend-block` |
| virtualization | `podman` `libvirt` |
| storage | `nas-smb` |
| flake 级 | `kernel-715` `agenix-secrets` |

无条件启用 (所有机器): modules/common 基础 + options + hardware-profile,
xwayland/NIXOS_OZONE_WL, openssh/resolved/firewall, development/opencode, documentation,
btmtk-fix (内部双重条件: bluetooth 标签 + 内核 < 6.12.93)。

当前机器: **NixMEOW** (全部标签) / **NixMEOW-WSL** (仅 `compositor-niri`)。

## 4. 验证

- NixMEOW-WSL 完整 eval ✓: `nixos-system-NixMEOW-WSL-26.05....drv` 生成
- NixMEOW-WSL build ✓: (见 git 提交记录)
- NixMEOW 零行为变化: 改造前快照 (`/root/baseline`) 与改造后 toplevel 用 nix-diff 对比,
  差异应仅限 flake source hash (结构重构必然改变 self source)

## 5. 踩坑记录

1. **`lib.mkIf cond (lambda 模块)` 不合法** — mkIf 只能包 attrset;
   函数模块要在内部对 option 用 mkIf (报错形如 "trying to define a value of type lambda")。
2. **NixOS-WSL 设 `services.timesyncd.enable = false`** — 共享模块里的无条件 true 会冲突,
   用 `lib.mkDefault true` 让位 (NixMEOW 行为不变)。
3. **`meow` 胶水模块必须先于 hosts 导入** — 不影响正确性但语义上是"先注册标签再消费"。
4. `imports` 不能依赖 config 值 (条件 import 是反模式), 所以叶子模块在文件内部 mkIf。
5. **Nix 函数形参必须显式声明才在作用域内** — `...` 只静默多余参数,
   不会把 caller 传的 `lib` 绑进作用域 (报 undefined variable 'lib')。
6. **HM 选项拼写**: `manual.manpages.enable` (小写 p); 26.05 把
   `documentation.man.generateCaches` 改名为 `documentation.man.cache.enable`。
7. **WSL build 的网络坑三连**:
   - nixos-render-docs 的 python 依赖在 cache.nixos.org 404 (上游没构建) → 试验台直接
     `documentation.nixos.enable = false` + HM `manual.manpages.enable = false`;
   - 走代理大文件传输 SSL EOF — flake nixConfig 的 `http2 = false` 对 daemon 无效,
     要写进 daemon 的 /etc/nix/nix.conf (session hack, switch 后会被 NixOS 重新生成);
   - daemon 的 /etc/nix/nix.conf 会被莫名回滚, 改完要 `systemctl restart nix-daemon` 并复查。

## 6. home/ 树的标签化 (2026-09-22 追加)

home-manager 同样吃 meow 标签 (mkHost 把 `meow = { kind, features }` 加进
extraSpecialArgs), `home/Reiky-REI/default.nix` 按组自我屏蔽:
`apps` / `music` 是最重的 GUI 组, `kind == "wsl"` 时跳过 (closure 差 ~2-3G,
也绕开 krita/dolphin 等大包 substitute 不稳的问题); NixMEOW (kind=laptop) 全量不变。

## 7. 后续 (Phase 3+, 未做)

- home/ 树标签化仅到分组级 (apps/music); desktop/apps 内部粒度 (如 wallpaper/hyprlock) 待细化
- overlay 里的 zen-ime wrap / qq / netease 仍无条件 (eval 无害)
- `nixos-generators` (同配置出 wsl/vm/iso) 备选未引入
- `modules/features/` 文件名即标签的 readDir 自动注册 (lib/features.nix) 备选未引入
