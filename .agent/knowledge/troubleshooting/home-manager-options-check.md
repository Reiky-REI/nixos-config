# Home Manager 选项 vs NixOS 选项误判

## 现象
把 `services.swaync`、`services.swayidle`、`services.polkit-gnome` 从 `home/default.nix` 移到 NixOS `modules/` 后，`dry-activate` 报 "option does not exist"。

## 根因
这些选项是 **home-manager 的 `services.*`**，不是 NixOS 的 `services.*`。

| 选项 | 存在位置 |
|------|----------|
| `services.swaync.enable` | home-manager |
| `services.swayidle.enable` | home-manager |
| `services.polkit-gnome.enable` | home-manager |

NixOS 没有这些选项。它们只能放在 home-manager 的 `imports` 链中。

## 如何判断一个选项是 HM 还是 NixOS

### 方法 1: 搜 nixpkgs 源码
```bash
# NixOS 选项
find /nix/store/*nixpkgs*/nixos/modules -name "*.nix" | grep -i swaync

# home-manager 选项  
find /nix/store/*home-manager*/modules -name "*.nix" | grep -i swaync
```

### 方法 2: 看配置文件路径
- `modules/desktop/` → NixOS 系统模块
- `home/Reiky-REI/` → home-manager 模块

### 方法 3: 试 `nixos-option`
```bash
nixos-option services.swaync          # 查 NixOS
man home-configuration.nix  # 查 HM
```

## 教训
1. **不要假设一个 `services.*` 选项两者都有** — 90% 是互通，但不全是
2. 上移 home 配置到 modules 之前先验证目标是否存在
3. polkit-gnome/swaync/swayidle 是用户级 daemon，放 home 逻辑正确
