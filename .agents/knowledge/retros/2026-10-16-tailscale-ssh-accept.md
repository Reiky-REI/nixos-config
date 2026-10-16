---
date: 2026-10-16
module: modules/networking/tailscale.nix, tailnet ACL (云端, 非仓库)
tags: [tailscale, ssh, acl, api, remote-access, check-mode, accept-mode, netmap]
layer: system
severity: low
related:
  - 2026-05-26-tailscale.md
---

# 复盘: Tailscale SSH 远程登录免密 + ACL check→accept 免浏览器验证 (2026-10-16)

## 背景

用户想从其他设备 (iPad / Windows / 手机) 通过 Tailscale SSH 进本机 nixmeow 喵~

## 现状排查

- 运行时已就绪: tailscaled 已连接喵, `RunSSH: true`喵, MagicDNS `nixmeow.miku-garibaldi.ts.net` (100.126.4.97) 喵~
- ACL 为默认模板: ssh 规则 `action: check` → 连接需浏览器确认 (netmap 显示 `holdAndDelegate`) 喵~
- 缺口: `--ssh` 只存在于 tailscaled 运行时 state 喵, 未进 Nix 配置 → state 重置后 Tailscale SSH 会静默关闭喵~

## 改动

1. `modules/networking/tailscale.nix`: 自动重连脚本补 `--ssh` 喵~ (commit `bbbb879`, build 通过并核验产物脚本) 喵~
2. tailnet ACL: ssh 规则 `check` → `accept` 喵~ (云端改动, 经 API 写入, netmap 复核 `"accept": true`) 喵~

## 可复用操作路径 (ACL via API)

1. 管理台 Settings → Keys 生成 API access token (短有效期) 喵~
2. `GET /api/v2/tailnet/-/acl` — 直接返回原始 HuJSON 策略文档 (带注释) 喵~
3. 文本级修改 (如 `"action": "check"` → `"action": "accept"`) 喵~
4. `POST /api/v2/tailnet/-/acl/validate` 先校验 (200 + `{}` = 通过) 喵~
5. `POST /api/v2/tailnet/-/acl` 写入, 带 `If-Match: <GET 的 etag>` 防并发覆盖喵~
6. 生效验证: `sudo tailscale debug netmap` → `SSHPolicy.rules[].action` (check = `holdAndDelegate`; accept = `accept: true`) 喵~
7. 收尾: 删本地 token 文件 + 管理台撤销 token 喵~

## 回退方式

管理台 ACL 把 `"action": "accept"` 改回 `"check"` 即恢复浏览器验证喵~

## 备注

- 免验证代价: tailnet 内本人名下设备可免任何验证 ssh 进本机 (非 root 用户) 喵~ 本 tailnet 全为本人设备, 可接受喵~
- Tailscale SSH 接管 tailscale 接口的 22 端口喵, 局域网访问仍走普通 sshd (密码认证) 喵~
