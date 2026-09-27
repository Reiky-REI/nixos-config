---
date: 2026-09-27
module: users.nix, machines.nix, lib/mkHost.nix, modules/common/options.nix, flake.nix
tags: [nixos, multi-host, multi-user, multi-agent, registry, roles]
layer: common
severity: high
related:
  - ../decisions/nixos-multi-dimension-registry.md (Host/User/Agent 正交注册模型)
  - 2026-05-30-hardware-profile-registry.md (原机器性能档位注册)
experience:
  - "Host、User、Agent 是正交维度，关系通过多对多绑定表达，不应建成互相继承的上下级树。"
  - "先把 user ID、login、home path、home profile 分字段登记，可支持多 host 同 user 与一 host 多 user，同时保留旧 home 目录。"
  - "feature ID 用 enum 类型校验，未知标签应在 eval 阶段失败而不是静默关闭能力。"
  - "多 host flake checks 应从注册表生成；单独验证一个 host 不足以防止共享模块回归。"
---

# NixMEOW 多维配置体系迁移

## 用户确认的模型

Host、User、Agent 是三套独立的实体，彼此以多对多关系组合；角色/能力只是 host 的属性，不代表 User 或 Agent 从属于 Host 喵~

## 阶段 A：用户注册与 host-user 绑定

- 新增 `users.nix` 稳定身份 ID，显式声明 login、homeDirectory、homeProfile 与 GitHub handle 喵~
- `machines.nix` 为 NixMEOW 与 WSL 声明 `users = [ "reiky" ]` 和兼容期 `primaryUser` 喵~
- `lib/mkHost.nix` 按 host 的 user 列表生成系统账号和 Home Manager 用户；Home profile 通过字段绑定，不依赖登录名推导喵~
- `config.nix` 保留成旧脚本兼容视图，避免无必要删除喵~
- `lib/features.nix` 与 `types.enum` 让未知 feature 在 eval 阶段报错喵~
- `flake.nix` 从 host registry 动态生成所有 NixOS toplevel checks 喵~

### 阶段 A 验证

- NixMEOW 与 NixMEOW-WSL 的 toplevel drvPath 与改造前完全相同喵~
- NixMEOW 与 WSL checks 均 build 通过喵~
- 临时注入第二个用户的 eval 同时生成了 system account 与 Home Manager 用户喵~
- 未知 user ID 与未知 feature 均在 eval 阶段失败喵~

## 阶段 B：能力分层

- 新增 `meow.roles` (`workstation`/`devbox`/`server`/`embedded`) 与 `lib/roles.nix` 校验, 与硬件档位 `profile` 解耦喵~
- 新增 `meow.desktopEffects` (`full`/`minimal`), Niri 效果档不再借用 `isHighPerf`喵~
- `modules/common` 中的字体、`programs.zsh`、sudo 免密与 polkit wheel 规则移入
  `modules/roles/interactive.nix`, 按 role 生效喵~
- 硬件层去掉无条件 `intel.updateMicrocode`、intel VA-API 驱动与 `enableAllFirmware`;
  AMD 微码与固件改由 `hosts/NixMEOW/hardware.nix` 声明喵~
- 桌面层 `programs.xwayland`、`NIXOS_OZONE_WL`、`xwayland-satellite` 按能力启用喵~
- 网络层 5900 端口与 `PermitRootLogin` 按 role 收紧喵~
- home 树按 role/能力分组: 桌面组、开发编辑器组、agent 工具组、worker 应用组分别按需导入,
  取代原来的 `kind == "wsl"` 二元特判喵~
- 服务模块的 `Reiky-REI` 硬编码路径改为 `primaryUser.homeDirectory`喵~
- `mkHost` 支持 per-host `system`, `flake checks` 按架构分组生成喵~

### 阶段 B 验证

- NixMEOW 与 NixMEOW-WSL 均 build 通过喵~
- NixMEOW 闭包 diff 仅含预期项: 移除 intel-media-driver/intel-vaapi-driver/intel-gmmlib
  (约 111MiB)、initrd 缩小约 14.4MiB, 属修正 AMD 机器上的错误依赖喵~
- server 角色合成求值: `niri`/`xwayland`/`zsh`/sudo 免密均为关, kitty/neovide/zed 不进入用户环境喵~
- 合成多用户求值仍同时生成系统账号与 Home Manager 用户喵~

## 后续阶段

阶段 C 产出 Docker systemd rootfs 镜像 (走 nixpkgs 内建 image 模块, 不引入已弃用的 nixos-generators)喵~
阶段 D 整理共享 agent registry 与客户端适配器喵~
