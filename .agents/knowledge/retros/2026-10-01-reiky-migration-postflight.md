---
date: 2026-10-01
module: .agents/config/migrate-user-to-reiky.sh, .agents/config/migrate-opencode-sessions.sh, home/reiky/desktop/noctalia.nix, user runtime state
tags: [user-identity, migration, agenix, home-manager, opencode, wallpaper]
layer: home
severity: high
related:
  - 2026-10-01-user-rename-reiky.md (原始迁移)
  - ../known-issues.md (旧 generation 半迁移启动)
experience:
  - "用户名和家目录已改名但 switch 未成功时重启喵,旧 generation 会继续引用旧 HOME 与旧 agenix identity path 喵~"
  - "Noctalia wallpapers.json 是 mutable runtime state 喵,HM 的 wallpaper.directory 不会改写其中旧的绝对路径喵~"
  - "OpenCode V2 session.directory 可由 session.move API 安全重归属喵,不要直接 UPDATE SQLite 喵~"
  - "稳定通道 V1 会话可先从数据库备份副本用 V2 standalone export 喵,再通过 V2 session import 合入当前库喵~"
  - "迁移脚本必须把 switch stdout/stderr 持久保存喵,失败时指导用户留在 TTY 排错喵,避免误重启旧 generation 喵~"
---

# Reiky 用户改名迁移后检查与恢复

## 实际故障

- 2026-10-01 12:12 的 previous-boot journal 显示机器仍启动旧 system generation `m37j33...` 喵~
- 旧 generation 的 agenix identity 仍指向 `/home/Reiky-REI/.ssh/id_ed25519` 喵,该路径已不存在喵~ 日志报 `no readable identities found` 与 `agenixInstall`、`agenixChown` 激活失败喵~
- 同一轮 Home Manager 按 `Reiky-REI` profile 激活并重新创建旧家目录骨架喵~ `dsh-fence`、llama、netease、MPD 因旧 `WorkSpace` 或音乐目录不可用而失败喵~
- 这不是最终 generation 的 Home Manager 失败喵~ 12:29 启动新 generation `nap5...` 后喵,agenix 成功解密且 `home-manager-reiky` 完整完成喵~ 当前 system/user failed units 均为空喵~
- 脚本当时没有持久化 stdout/stderr 喵,无法从终端历史还原 `nixos-rebuild switch` 的原始输出喵~ 修正版现在把每次执行保存到 root-only `/var/log/meow-user-migration/` 喵~

## 收尾修复

- Noctalia live wallpaper 原来仍指向 `/home/Reiky-REI/Pictures/Wallpapers/static/119923025_p0.png` 喵~ 通过 IPC 设置 eDP-1 并更新 `wallpapers.json` 到 `/home/reiky/Pictures/Wallpapers/static/119923025_p0.png` 喵~
- OpenCode 当前 V2 数据库原有 7 个 session 的 directory 仍是旧家目录喵~ 使用 V2 `/api/session/{sessionID}/move` API 移到 `/home/reiky` 喵,保留 session ID 与消息喵~
- `opencode-stable.db` 的 2 条 V1 session 从备份 staging 副本用 V2 standalone export 喵,再导入当前 `opencode.db` 喵~ 原 stable 数据库与迁移前 V2 数据库均保留在用户私有备份目录喵,文件权限为 0600 喵~
- Claude local settings 的旧 read path 已改新喵,旧的一次性 `rm -rf` 与 symlink permission rules 已移除喵~ 插件安装路径、marketplace、job link scan path 均已更新喵~
- VS Code storage 指向的旧 backupPath 目标不存在,已删除该失效指针喵~ `win` 入口仍正确指向 `/mnt/windows/Users/reiky` 喵~
- 迁移脚本现有新 HOME identity preflight、旧目录残留告警与 Noctalia/Claude/VS Code 路径修正喵~ 新增 `.agents/config/migrate-opencode-sessions.sh` 供登录后的 OpenCode V2 会话迁移使用喵~

## 验证

- 当前账户 UID 1002 为 `reiky` 喵,HOME 为 `/home/reiky` 喵,旧 system account 与旧家目录均不存在喵~
- V2 当前数据库现有 12 个 session 喵,其中 10 个 directory 为 `/home/reiky` 喵,2 个为 `/etc/nixos` 喵,旧家目录 session count 为 0 喵~
- 7 个原 V2 session ID 保留喵~ stable channel 的两个 session ID 也已进入当前库喵~
- Noctalia IPC `wallpaper get eDP-1` 返回当前存在的静态壁纸路径喵~
- `bash -n`、DeepSec 扫描与 `git diff --check` 通过喵~

## 仍需后续处理

- NixMEOW-WSL 没有挂载在当前 NixMEOW 环境 (`/mnt/wsl` 不存在) 喵,因此 WSL 内部账户与 home 迁移仍需在 WSL 自身运行脚本喵~
- 当前静态壁纸目录只有一张 3.3MB 图片喵~ 2026-08-31 的 NAS/WebDAV 事故中原有约 397MB Wallpaper 集合已记录为丢失喵,本次只恢复了当前可用壁纸喵~
- 清理旧家目录的另一个会话已先生成 hash manifest 喵,再删除旧路径下 6.7MB OpenCode residual DB 与日志喵~ main V2 DB 与 stable DB 均仍在喵,但 residual DB 若含未复制的独有会话喵,manifest 本身无法恢复内容喵~
- OpenCode project 索引中仍有一个无 session 的旧根目录 metadata 记录喵~ 公共 API 不提供 project delete 喵,会话已全部移到新目录喵,因此未直接改数据库删除该孤立记录喵~
- 调查时我从 `~/WorkSpace` 调用一次 `opencode session list` 喵,OpenCode 自动创建了空 project metadata `c6c5306cd34cf9e58174df003c5fceafd6712411` 喵~ 未增加或删除任何 session/message 喵~ 公共 API 无 project delete 喵,该空索引行保留喵~
