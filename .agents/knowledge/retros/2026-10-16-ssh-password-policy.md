---
date: 2026-10-16
module: modules/networking/tailscale.nix, tailnet 运行时 (nixmeow + deck)
tags: [tailscale, ssh, tailscale-ssh, password-auth, openssh, host-key, known-hosts, auth-policy]
layer: system
severity: medium
related:
  - 2026-10-16-tailscale-ssh-accept.md
  - 2026-10-16-steamdeck-tailscale.md
  - 2026-05-26-tailscale.md
---

# 复盘: SSH 认证策略定案 — 关闭 Tailscale SSH, 回归 OpenSSH 密码认证 (2026-10-16)

## 背景与决策

同日内两次偏好修正喵:

1. 早间: 用户要求"不要浏览器验证" → ACL check→accept (Tailscale SSH 免密直通)喵~
2. 晚间: 用户要求"至少要有用户密码" → Tailscale SSH 设计上不带密码 (tailnet 身份即认证),
   与需求冲突 → **关闭两台机器的 Tailscale SSH, 让 tailnet 的 22 端口回归普通 sshd,
   走用户密码认证**喵~

最终模型: **无浏览器验证 + 必须有用户密码** (两者兼得)喵~

## 改动

- nixmeow: `sudo tailscale set --ssh=false` → RunSSH=false喵~
- deck: `/opt/tailscale/tailscale set --ssh=false` (operator=deck 即可, 无需 sudo) → RunSSH=false喵~
- `modules/networking/tailscale.nix`: 撤销 `--ssh` 声明并留注释指向本复盘喵~
- ACL 的 ssh accept 规则保留但已无生效对象 (两台 Linux 都不再提供 Tailscale SSH;
  iPad/Windows 客户端本身不提供该服务)喵~ 若未来新设备启用 Tailscale SSH,
  该规则会放行免密访问, 需要留意喵~

## host key 迁移 (容易踩)

- 端口 22 的服务端从 tailscaled 切回 sshd 后, **主机密钥变了**喵~
- deck 侧旧 "nixmeow" 条目 (Tailscale 密钥) 清理: `ssh-keygen -R nixmeow`喵~
- nixmeow 侧因 `Host steamdeck` 带 `HostKeyAlias steamdeck.local`, 实测条目指向 sshd
  真实密钥, `ssh steamdeck` / `ssh deck@steamdeck.local` (StrictHostKeyChecking=yes) 均正常喵~
- 切换窗口内 (约 5 分钟) 客户端可能撞上 "REMOTE HOST IDENTIFICATION HAS CHANGED" 类报错,
  属过渡现象, 清理 known_hosts 后即恢复喵~

## 验证

- deck → nixmeow: `ssh reiky@nixmeow` → `Permission denied (publickey,password,keyboard-interactive)`
  (无免密入口, 密码方法在场; iPad 以密码方式登录 nixmeow 成功)喵~
- nixmeow → deck 经 tailnet/LAN: `ssh deck@steamdeck` 仍为密钥认证 OK — 这是 2026-09-29
  既有设计 (若也要强制密码, 需从 deck 的 authorized_keys 移除 nixmeow 公钥)喵~
- 两台 `tailscale debug prefs` 均 RunSSH=false喵~

## 展望

- 想要免密登录时, 用标准 SSH 公钥 (authorized_keys) 而非 Tailscale SSH, 保留密码兜底喵~
- 客户端首次连接会提示接受主机密钥, 属正常喵~
