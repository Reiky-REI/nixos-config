---
date: 2026-09-27
tags: [nixos, multi-host, multi-user, multi-agent, architecture]
---

# NixMEOW 多维注册表决策

## 决策

Host、User、Agent 是三个独立维度，不是父子层级；三者之间通过显式多对多绑定组合喵~

- 一个 user identity 可以绑定多个 host，一个 host 可以绑定多个 user identity 喵~
- 一个 agent 定义可以服务多个 user 与多个 host；agent 默认 host 范围可复用，但 user 必须显式授权喵~
- 特权 agent 还必须显式声明 host allowlist，防止能力随新增 host 扩散喵~
- Host 的 role 表示用途组合，feature 表示可组合能力；hardware/platform/profile 单独描述设备与运行条件喵~
- `homeProfile` 是 user identity 到 Home Manager 配置集的显式绑定，不从登录名或目录名推导喵~

## 配置覆盖边界

共享能力由 Nix modules 实现；host/user/agent 的绑定数据选择能力，不形成任意深度的隐式继承树喵~
明确的 host、user、agent 组合例外应显式记录，且 secret、session/runtime state 与共享 agent 定义分离喵~

## 阶段与兼容性

- 阶段 A：引入 users registry、host-user bindings、feature ID 校验与全 host checks；现有 NixMEOW/WSL 输出保持不变喵~
- 阶段 B：新增 `roles` 表示用途组合、`desktopEffects` 表示桌面效果档，与硬件 `profile` 解耦；
  交互/图形/硬件能力按 role 与 feature 自我屏蔽，微码与固件放 host 本地喵~
- 阶段 C：使用 NixOS 内建 Docker rootfs/tarball module 产出 systemd PID 1 容器镜像；不引入已弃用的 nixos-generators flake 喵~
- 阶段 D：定义 agent registry，并用 OpenCode/Claude/Codex 客户端适配器输出配置；共享定义不包含用户凭据喵~
- 阶段 D 作用域规则：`hosts` 默认全部 host、`users` 必须显式列出、`privileged` 必须写非空 `hosts.allow`；
  实际生效范围是 `(agent, user, host)` 交集喵~

## 验证要求

- 注册表引用到未知 host/user/agent/feature 应在 eval 阶段失败喵~
- checks 覆盖注册 host；组合例外需有对应 eval/build 验证喵~
- system-level NixOS 选项仍需系统 build/activation；Home Manager 与 live application config 的局部迭代单独设计喵~
