---
date: 2026-09-28
tags: [nixos, home-manager, reproducibility, multi-host, secrets, systemd, retirement]
---

# 配置复现与 bot 集成退役

## 决策

- `/etc/nixos` 是系统与 Home Manager 静态配置的唯一版本来源喵~
- Host 和 User 保持正交喵,`machines.nix` 选择用户身份与 host capability 喵,`users.nix.homeProfile` 选择可复用的 user profile 喵~
- `lib/mkHost.nix` 不从 `~/.config` 或 WorkSpace 动态导入 Nix 文件喵,Home Manager 服务定义放在 `home/<profile>/` 喵~
- host 特有的显示器映射、背光设备与 KB corpus roots 显式放在 `machines.nix` 喵~
- 应用可写配置以 Nix 静态基线加运行时深度合并管理喵,密钥、cache、session 与程序生成状态不得进入 Nix store 喵~
- AstrBot、NapCat、DSH-AstrBot bridge、mcp-agents-bridge 与专用 opencode-root 通道退役喵~

## 为什么这样选

原先 `mkHost.nix` 会尝试读取家目录的 `~/.config/home-manager/services/*.nix` 喵,纯 flake 求值没有把这些文件纳入输入喵~ 因此它们既不可靠参与构建喵,也无法由 Git 审查和备份喵~

桌面设置同时有稳定偏好和应用状态喵~ Noctalia、SPlayer、YouTube Music 使用可写 JSON 深度合并喵,Zed 交给 Home Manager 的 mutable settings merger 喵,静态源不含 API token 喵~ Niri、Zellij、btop、Superfile、Cava、Fcitx5、Pigma、GitHub CLI 与 DSH profile 的可复现配置落入 Home profile 喵~

## Host 与 User 组合

- Host 从 `machines.nix` 选择多个 user ID 喵,User 从 `users.nix` 映射到可复用 `homeProfile` 喵~
- `NixMEOW` 为当前 Noctalia widgets 声明显示器名喵,WSL 与 container host 使用各自 capability 设置喵~
- 新 user 通过新增 `users.nix` identity 与 Home profile 接入喵,新 host 通过 `machines.nix.users` 显式绑定已有或新 user 喵~
- 求值和 build checks 覆盖所有已注册 hosts 喵,不枚举无效的 Host × User 组合喵~

## 退役与归档

- AstrBot、NapCat、mcp-agents-bridge 与 opencode-root 当前服务已停止喵,DSH-AstrBot plugin 已从 DSH profile 配置移除喵~
- 用户确认数据先归档再清理喵,archive 与逐文件 SHA-256 manifest 已 age 加密到 NAS 喵~
- 加密归档、模块源码快照与旧用户配置索引见 `docs/archive/retired-integrations/README.md` 喵~
- 当前 DSH profile 无 AstrBot bridge 配置喵,DSH fence 重启后 `/plugins/astrabot/health` 返回 404 喵~
- 系统 `dsh-fence` 保留喵,它仍提供 DSH web UI 喵~

## 凭据边界

- Netease Cookie 从 Nix 服务源码移除喵,运行时由 workspace 私有 `.env` 提供喵~
- Noctalia Wallhaven key、Zed GitHub PAT、Nix access token、Minlai API key 与 GitHub CLI auth 文件均不进入 Nix store 喵~
- 已经进入旧 Git history 的 Netease/AstrBot 明文凭据需要轮换喵~

## 执行状态

- 归档验证通过喵,age 解密、Zstandard checksum、tar listing 与 manifests 比对均通过喵~
- 用户数据原目录的删除操作被当前 shell permission gate 拒绝喵,原始目录仍在本机喵,备份已完成喵~
- NixMEOW、NixMEOW-WSL 与 NixMEOW-CTR 均通过求值喵,NixMEOW 的 `nixos-rebuild build` 成功喵~
- 用户确认风险后执行 NixMEOW `nixos-rebuild switch` 喵,首次 Home Manager activation 因既有配置文件冲突失败喵~
- 设置 `home-manager.backupFileExtension = "hm-backup"` 后再次 switch 成功喵,Home Manager activation 完成并将旧文件保留为 `.hm-backup` 喵~
- 当前 NixOS generation 已切换喵,`dsh-fence`、polkit、NetworkManager 与 Netease service 均 active 喵~ `mcp-agents-bridge` 与 `opencode-root` 均 not-found 喵~
