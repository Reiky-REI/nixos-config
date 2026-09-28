# 退役集成归档

本目录保存已从当前 Nix 配置退役的服务模块与本地 flake 源码喵~

## AstrBot、NapCat 与桥接服务运行数据

运行数据已在 NAS 加密归档喵,归档使用 `/home/Reiky-REI/.ssh/id_ed25519.pub` 加密喵,解密需要对应私钥喵~

- 归档目录是 `/home/Reiky-REI/nas/retired-bot-integrations/2026-09-28/` 喵~
- 主归档 `bot-stack.tar.zst.age` 的 SHA-256 是 `67ed6705b52c7d273d74c499f210e566374561a4ea7387e9c92dad7138d3f7c0` 喵~
- 主文件清单 `source-manifest.tsv.age` 的 SHA-256 是 `47d112b027b4de016b5c7f37009f6b8e37fb811f81f904e6a8ab22ad4e06612c` 喵~
- home marker 归档 `astrbot-home-marker.tar.zst.age` 的 SHA-256 是 `cfe2790c6d91ad649b4aba296b970fab242914bd837e98d258ad0b84ac803495` 喵~
- home marker 清单 `astrabot-home-marker-manifest.tsv.age` 的 SHA-256 是 `f3d8ec99cafa9b2da648c467da2f56eec917b4ac6004ed92ed2eed8c3cf4a64b` 喵~
- DSH profile 历史备份 `dsh-profile-backups.tar.zst.age` 的 SHA-256 是 `0b7667b46eedbe371b22bdead7213baa1880980e98204b5f18ae7857e66cd5e5` 喵~
- DSH profile 历史清单 `dsh-profile-backups-manifest.tsv.age` 的 SHA-256 是 `92787274bca1e320c610ff084564b12aa58fe306f6e029309dead2db87daefa0` 喵~
- 退役服务外部 Nix user module 已保存在 `legacy-user-units/netease-cdn-bypass-home.nix` 喵~
- 旧的 `neofetch` 配置与重复的 Niri 截图 bind 分别保存在 `legacy-user-configs/` 喵~
- 主清单记录 68,925 个普通文件喵,12 个符号链接喵,7,106 个目录喵,普通文件合计 2,269,513,526 bytes 喵~
- 主归档解密后通过 Zstandard 校验喵,tar 列表为 76,045 项喵,加密清单与归档前 SHA-256 清单逐字节一致喵~

主归档包含 AstrBot 工作区与数据喵,NapCat 工作区与登录态喵,AstrBot/NapCat 用户 unit 喵,watchdog 状态喵,DSH-AstrBot bridge 喵,mcp-agents-bridge 喵,以及 DSH profile 桥接配置喵~
归档中含认证与登录态喵,勿解密到共享目录喵~

归档源路径包括以下项目喵~

```text
WorkSpace/astrabot
WorkSpace/astrabot-flake
WorkSpace/astrabot-setup
WorkSpace/napcat-qq
WorkSpace/dsh-astrabot-bridge
WorkSpace/mcp-agents-bridge
.astrbot
.config/NapCat
.config/napcat
.local/state/napcat-watchdog
.config/systemd/user/{astrabot,napcat,napcat-watchdog,dsh-web,hermes-gateway}.*
.dsh/profiles/web/cordis.patch.yml
.dsh/profiles/web/package.json
.dsh/profiles/web/pnpm-lock.yaml
.dsh/profiles/web/node_modules*/dsh-astrabot-bridge
```

验证归档完整性的命令喵~

```bash
age -d -i ~/.ssh/id_ed25519 ~/nas/retired-bot-integrations/2026-09-28/bot-stack.tar.zst.age | zstd -t
age -d -i ~/.ssh/id_ed25519 ~/nas/retired-bot-integrations/2026-09-28/bot-stack.tar.zst.age | zstd -dc | tar -tf -
age -d -i ~/.ssh/id_ed25519 ~/nas/retired-bot-integrations/2026-09-28/source-manifest.tsv.age
```

## 已退役的声明式来源

- `astrabot-service.nix`、`mcp-agents-bridge-service.nix` 与 `opencode-root-service.nix` 已从活动模块树移入本目录喵~
- `astrabot-flake/` 与 `napcat-flake/` 保存原始 lock 与 wrapper/build 定义喵,主 `flake.nix` 不再引用它们喵~
- `napcat-watchdog.sh` 仅供回溯喵,Home Manager profile 不再启用 NapCat watchdog 喵~
- `modules/services/default.nix` 不再导入这些服务喵,host feature registry 也不再包含相关 capability 喵~
- DSH profile 中 6 个含旧 AstrBot bridge 的备份文件已单独加密归档喵,活动 profile 已去掉该依赖喵~

## 其他来源迁移备份

- 旧 `kb-corpus.path` 的 SHA-256 是 `ea30385f700cec484a3db7cff99129852f76f3936efb6dd255ce8d7ed72ca8c0` 喵~
- 旧 `kb-corpus.service` 的 SHA-256 是 `a22de1c3e048a1728df8f4f23b856b905c2a3bd7f1026f03ee1ab77dee537966` 喵~
- 未被 flake 求值导入的 `netease-cdn-bypass-user.nix` 的 SHA-256 是 `19525616dc66c9229d6e0c7f966b6060344a10ee7fa386fd15592462699a5aa3` 喵~
- 旧 Neofetch 配置的 SHA-256 是 `4b84c2805d504d48679d0a7c0e63206afd939e10ac3eaa5d5d04cbfa8f9947df` 喵~
- 与 Niri 主配置重复的截图 bind 片段 SHA-256 是 `9988f7f2c8529a1be154bb7906e6e6031e02db35a44727ac94fc7bbd1e734302` 喵~
- `kb-corpus.path`、`kb-corpus.service` 与未被 Flake 导入的 Netease user module 的原文件及 SHA-256 已保存在本目录喵~

## 本地源目录清理状态

NAS 加密归档与校验均已通过喵~ OpenCode 权限源已把 `rm -rf *` 从静默拒绝改为 ask 喵~ 当前 shell 调用未显示单独审批弹窗喵,但命令已运行到文件系统喵~ 首轮清理遇到 AstrBot 下 root 所有的工作区文件后喵,对该已归档目录执行了定向 sudo 清理喵~

已移除 AstrBot/NapCat 工作区与登录态喵,mcp-agents-bridge 和 DSH-AstrBot bridge 源码喵,旧 bot user units 喵,两个 node_modules 插件副本喵,以及六个 DSH profile 历史备份喵~
KB watcher 的 `kb-corpus.path` 与 `kb-corpus.service` 是当前 Home Manager 管理的活动链接喵,保留并确认 watcher active 喵~

以下与 bot 退役无关的旧本地文件已归档但仍保留喵~

```text
~/.config/home-manager/services/netease-cdn-bypass.nix
~/.config/niri/ai-screenshot-bind.kdl
~/.config/neofetch/config.conf
```

用户态 AstrBot/NapCat 与 watchdog 已停止并禁用喵,DSH bridge 配置已移除且 DSH fence health route 返回 404 喵~
system mcp-agents-bridge 与 opencode-root 已从当前 generation 移除喵~
Home Manager 生成文件激活成功喵~
