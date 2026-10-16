---
date: 2026-10-16
module: Steam Deck (deck@steamdeck, 非仓库设备), tailnet API 操作
tags: [tailscale, steamdeck, steamos, ssh, sudoers, api, authkey, remote-access, deck-tailscale]
layer: system
severity: medium
related:
  - 2026-05-26-tailscale.md
  - 2026-09-29-steamdeck-mdns-hostname.md
  - 2026-10-16-tailscale-ssh-accept.md
---

# 复盘: Steam Deck 接入 Tailscale (deck-tailscale + API authkey 免浏览器) (2026-10-16)

## 背景

用户要求把 Steam Deck (steamdeck.local / 192.168.124.24, SteamOS holo) 也接入 tailnet喵,
目标是跨设备免密 SSH (deck ↔ nixmeow 等)喵~

## 现场

- deck 无 tailscale; 根文件系统只读 (steamos-readonly enabled); sudo 需密码 (无法非交互)喵~
- deck 访问 GitHub 超时, 但 pkgs.tailscale.com 可达 (1.2s)喵~
- deck 上已有 2026-01 克隆的 `~/deck-tailscale` (tailscale-dev 官方安装脚本, 内容与上游一致)喵~
- nixmeow 侧前置已就绪: Tailscale SSH + ACL accept 模式 (见 2026-10-16-tailscale-ssh-accept.md)喵~

## 关键踩坑: SteamOS sudoers.d 加载顺序

- 给 deck 建 `/etc/sudoers.d/99-ai-temp` (NOPASSWD) 后 `sudo -n` 仍要密码喵~
- 根因: sudoers.d 按**文件名排序**加载, **后加载的匹配规则生效** (last match wins)喵~
  SteamOS 自带 `wheel` 文件 (`%wheel ALL=(ALL) ALL`) 排序在 `99-ai-temp` **之后** ("9" < "w"),
  NOPASSWD 被它覆盖喵~
- 修复: 更名 `zz-ai-temp` (排序最后) 即生效喵~ 收尾删除后 deck sudo 恢复要密码喵~
- 教训: 在 sudoers.d 抢优先级要用**排序最后**的文件名 (zz-), 不是常见的 "99-"喵~

## 安装 (tailscale-dev/deck-tailscale)

- `sudo bash ~/deck-tailscale/tailscale.sh`: 二进制装 `/opt/tailscale/`,
  unit `/etc/systemd/system/tailscaled.service` + override, 开机自启喵~
- 持久化: 脚本写 `/etc/atomic-update.conf.d/tailscale.conf` (SteamOS 原子更新保留清单)喵~
- 自更新: `tailscale set --auto-update` (PATH 无 /opt/tailscale 时用全路径)喵~
- SteamOS 大版本更新后如失效, 重跑 tailscale.sh 即可喵~

## 免浏览器入网 (authkey via API)

- `tailscale up` 默认走交互 URL + 浏览器确认; 用户要求免浏览器喵~
- 管理台 API token → `POST /api/v2/tailnet/-/keys` 生成 `preauthorized: true` 一次性
  authkey (expirySeconds=3600) → deck 上 `tailscale up --authkey=tskey-auth-... --operator=deck --ssh` 直接入网喵~
- 收尾: authkey 用后即删; API token 也经 API **撤销** (DELETE /keys/{id}, 复核返回 401)喵~
- 注: API token 曾被 echo 进 `~/.zsh_history`, 已 sed 清理 (残留 0)喵~
- 注: 入网当天晚些时候按用户要求关闭 Tailscale SSH (`set --ssh=false`),
  SSH 改走密码认证, 详见 `2026-10-16-ssh-password-policy.md`喵~

## 验证

- deck: BackendState=Running, KeyExpiry 2027-04-14 (与 nixmeow 同为 180 天策略), tailscaled enabled喵~
- `tailscale ping steamdeck`: pong via 192.168.124.24:41641 (LAN 直连打洞)喵~
- nixmeow → deck: `ssh deck@steamdeck` 密钥认证 OK (既有 id_ed25519; TS SSH 当晚关闭后复测仍通)喵~
- deck → nixmeow: 初测免密钥 OK; 当晚按用户要求改密码认证, 复测 `Permission denied (publickey,password,...)` = 免密入口已断喵~
- deck sudo: 临时免密文件已删, `sudo -n` 恢复 "a password is required"喵~

## 教训 (操作细节)

- curl 输出勿把 stderr 合并后直接喂 JSON 解析: 首轮 authkey 创建响应混入了 curl 报错行,
  导致解析失败; 应先 `--retry` 且分离 stdout/stderr喵~
- 非交互装包/改系统前先检查目标机 sudo 是否需密码, 需密码时用"临时免密 sudoers 文件"桥接,
  收尾即删并复核恢复喵~

## 备注

- deck 常规 LAN 访问不受影响 (steamdeck.local → OpenSSH sshd); tailnet 访问同端口 22 回归 OpenSSH (Tailscale SSH 当日已关, 密码认证)喵~
- 凭证纪律: API token 不入 shell 历史/明文散落; 用完即撤, 需要时再生成喵~
