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

## 后续阶段

阶段 B 按角色/平台/硬件拆分能力；阶段 C 产出 Docker systemd rootfs 镜像；阶段 D 整理共享 agent registry 与客户端适配器喵~
