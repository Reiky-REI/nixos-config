---
date: 2026-09-28
module: flake.nix, lib/mkHost.nix, home/Reiky-REI, modules/services, machines.nix
tags: [nixos, home-manager, reproducibility, multi-host, secrets, systemd, bot-retirement]
layer: common
severity: high
related:
  - ../decisions/config-reproducibility-and-retirement.md (配置来源与 bot 退役决策)
  - ../retros/2026-09-27-multidimensional-config.md (Host/User 注册模型)
experience:
  - "Flake-evaluated Home Manager imports must be repo-relative; host-home filesystem reads are not reproducible under pure evaluation喵~"
  - "Mutable JSON settings can retain app-owned credentials by deep-merging a sanitized static Nix baseline into the writable runtime file喵~"
  - "Host-specific monitor and backlight names belong in the host registry and should be passed to user profiles as validated values喵~"
  - "Retiring an app stack requires disabling its services, preserving the runtime data archive, and separately checking all DSH/plugin references喵~"
---

# 配置复现治理与 bot 集成退役

## 配置来源收口

- 移除了 `lib/mkHost.nix` 对 `~/.config/home-manager/services/*.nix` 的动态扫描喵~
- 活动 Home Manager 模块、用户配置与服务定义现在来自 `/etc/nixos/home/<profile>` 喵~
- Host 注册表增加 Noctalia monitor mapping、backlight device 与 KB workspace corpus roots 喵~
- Cava、Fcitx5、OpenCode、Noctalia、Zed、Zellij、btop、Superfile、GitHub CLI、Pigma、SPlayer、YouTube Music 与 DSH profile 设置已纳入 Home Manager 源码喵~
- Noctalia、SPlayer、YouTube Music 使用保留应用运行状态的 JSON 深度合并喵,Zed 使用 Home Manager mutable settings merger 喵~
- DSH profile package manifest、pnpm lock 与 Cordis patch 现在有仓库内来源喵~
- 首次切换时 HM `checkLinkTargets` 拒绝覆盖已有用户配置喵~ 设置 NixOS HM `backupFileExtension = "hm-backup"` 使旧文件保留在旁并让新 generation 正常部署喵~

## 常驻服务与 watcher

- `kb-corpus.path/service` 与 NapCat watchdog 的 Nix 定义迁入 Home Manager 喵~
- KB `warm-all.sh` 以显式 Bash 执行喵,修复原 unit 因不可执行文件报 `203/EXEC` 的失败喵~
- `kbdlight-sync` 改为 host registry 指定 backlight 设备喵,并让 Niri event stream 持续订阅而非每 120 秒重连喵~
- 已停用 legacy `astrabot.service`、`napcat.service`、watchdog timer、失败的 `dsh-web` 与 Hermes gateway 喵~

## 退役与归档

- 用户明确要求退役 AstrBot、NapCat 与整个 MCP agents bridge 喵~
- AstrBot、NapCat、mcp-agents-bridge 与 opencode-root 服务已停止喵,DSH AstrBot plugin 从 Cordis/package/lock 删除喵~
- DSH fence 在无 established clients 时重启喵,`/plugins/astrabot/health` 返回 404 喵~
- 运行目录已使用 SSH recipient age 加密归档到 NAS 喵,主 archive 与逐文件 hash manifest 均通过验证喵~
- 由于 shell permission gate 拒绝原目录删除喵,WorkSpace、NapCat session、node_modules plugin 与 user unit 源文件仍保留在本机喵~

## 凭据边界

- Nix 源码已移除 AstrBot dashboard 初始密码与 Netease Cookie 字面量喵~
- Nix、Minlai、Zed、Noctalia 与 Netease 凭据仍是运行时输入喵,敏感本地配置权限已限制喵~
- 已经存在于旧 Git 历史的 Netease Cookie 与 AstrBot 密码需轮换喵~

## 验证

- NixMEOW、NixMEOW-WSL 与 NixMEOW-CTR 的 toplevel 均求值成功喵~
- NixMEOW `nixos-rebuild build` 与用户确认风险后的 `nixos-rebuild switch` 均成功喵~
- 首次 switch 的 HM activation 曾因旧配置冲突失败喵,启用 `hm-backup` 策略后重试成功喵~
- `dsh-fence`、polkit、NetworkManager、Netease service active 喵~ mcp-agents-bridge/opencode-root 为 not-found 喵~
- JSON/TOML/YAML、Bash 与 Nix syntax、DeepSec 目标目录扫描及 `git diff --check` 均通过喵~
