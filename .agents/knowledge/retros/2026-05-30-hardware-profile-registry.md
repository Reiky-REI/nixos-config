---
date: 2026-05-30
module: machines.nix, modules/common/hardware-profile.nix, flake.nix, home/Reiky-REI/desktop/niri/, README.md
tags: [架构, 多机器, 硬件档位, niri, 注册机制]
layer: common
severity: medium
related:
  - ../../known-issues.md (HM 模块访问 NixOS config 的注意事项)
  - ../retros/2026-05-27-config-user-center.md (config.nix 用户配置中心)
experience:
  - "home-manager 模块不能直接读取 NixOS 的 config.hardware，需通过 extraSpecialArgs 传递"
  - "Nix flake eval 需要文件先 git add，否则报 path does not exist"
  - "KDL 不支持块节点部分覆盖，拆配置时需确保每个块完整自包含"
  - "Nix 模块列表中函数模式需用括号包裹以避免解析歧义"
---

# 硬件档位注册机制 + Niri 配置分拆

## 改动内容

### 新增文件
- **`machines.nix`** — 机器注册中心，hostname → profile 映射
- **`modules/common/hardware-profile.nix`** — 自检测选项定义（`hardware.profile` / `isHighPerf` / `isLowPerf` / `isMediumPerf`）
- **`home/Reiky-REI/desktop/niri/sections/base.kdl`** — Niri 共享配置段（快捷键、输入、环境变量）
- **`home/Reiky-REI/desktop/niri/sections/high.kdl`** — 高性能专属（blur、shadow、动画、半透明）
- **`home/Reiky-REI/desktop/niri/sections/low.kdl`** — 低性能专属（无特效、极简动画）

### 修改文件
- **`flake.nix`** — `extraSpecialArgs` 传递 hardware profile 到 HM 模块
- **`modules/common/default.nix`** — import hardware-profile.nix + `nix.settings.max-jobs` 按档位调整
- **`home/Reiky-REI/desktop/niri/default.nix`** — 改为根据档位组合 kdl 段
- **`home/Reiky-REI/apps/media.nix`** — 移除已废弃的 `cider`
- **`README.md`** — 全面更新：目录树修正、机器注册说明、Just 命令表、新架构说明

## 信息流向

```
machines.nix (hostname → profile)
  → hardware-profile.nix (自检测 → NixOS 选项)
    → flake.nix extraSpecialArgs (传递到 HM)
      → niri/default.nix (选 kdl 段)
      → max-jobs (选构建并行度)
```

## 技术难点

1. **NixOS → HM 的选项传递**：home-manager 模块的 `config` 是 HM 自己的配置树，不能直接读 `config.hardware`。需在 NixOS 侧的 `extraSpecialArgs` 中 `inherit (config.hardware) profile isLowPerf ...`。

2. **KDL 块节点不可部分覆盖**：`cursor { ... }`、`layout { ... }` 等块节点在 KDL 中如果出现两次，后一个完全覆盖前一个（Niri 的 KDL 解析器不合并）。因此分拆时确保同一节点只在一个文件中出现。

3. **Nix 列表中函数模式的括号**：`[ { config, ... }: { ... } ]` 需要写成 `[ ({ config, ... }: { ... }) ]`，否则 Nix 解析器会报语法错误（将 `{ config` 解释为集合字面量而非函数模式）。

## 后续可优化

- `terminal/kitty.nix` — 条件 `background_opacity` / `background_blur`
- `modules/desktop/ly/settings.nix` — 条件 `animation`
- `modules/desktop/default.nix` — 条件 `programs.steam` 启用
- `desktop/hyprlock/default.nix` — 条件 `blur_passes`
- 添加 medium 档位的完善配置（当前 medium 复用 low）
