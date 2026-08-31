---
title: "DSH fence trusted-host 配置 - 修复 Tailscale 域名 API 403"
requester: "NixMEOW/claude-code"
date: "2026-08-19"
request_id: "2026-08-19-dsh-fence-trusted-host"
priority: "high"
status: "rejected"
---

## 申请内容

配置 DSH fence 的 trusted-hosts，让通过 Tailscale 域名 `nixmeow.miku-garibaldi.ts.net:3080` 访问 DSH web 时 API 不被 403 拦截喵~

## 为什么需要

用户通过 Tailscale 代理访问 DSH web 端（`https://nixmeow.miku-garibaldi.ts.net:3080`），遇到两个问题：

1. **`crypto.randomUUID is not a function`** - 浏览器 Web Crypto API 只在安全上下文（HTTPS/localhost）下可用，已通过启用 Tailscale HTTPS 解决
2. **`transport failure for /api/host.listDirectory: HTTP 403`** - DSH browser-trust fence 拦截了 API 请求，因为 `Host` 头不在受信任列表中

## 当前状态

- DSH 由 systemd 接管，服务文件在 `/etc/nixos/modules/services/dsh-fence.nix`
- `trustedHosts` 选项已定义但默认为空列表
- ExecStart 已有 `--trusted-host` 参数拼接逻辑：`${lib.concatStringsSep " " (map (h: "--trusted-host ${h}") cfg.trustedHosts)}`

## 具体方案

1. 在主机配置（`/etc/nixos/hosts/MEOW/`）中设置 `services.dsh-fence.trustedHosts = ["nixmeow.miku-garibaldi.ts.net"];`
2. 如果还有其他访问方式（如 `100.126.4.97:3080`），一并加入
3. `nixos-rebuild build` 验证配置正确
4. 复盘到 `knowledge/retros/`

## 预期影响

- DSH web 通过 Tailscale 域名访问时，API 请求不再被 403 拦截
- `crypto.randomUUID()` 在 HTTPS 上下文中正常工作
- 其他访问方式（localhost 等）不受影响

## 验证方式

- `nixos-rebuild build --flake /etc/nixos#NixMEOW` 通过
- `systemctl status dsh-fence` 确认服务正常
- 通过 `https://nixmeow.miku-garibaldi.ts.net:3080` 访问 DSH web，API 功能正常

## 处理记录 (2026-09-01 claude-code 归档)

**结论: `rejected` — 不按原方案执行, 原因是运行时架构已漂移喵~**

1. 原方案的 `services.dsh-fence.trustedHosts` 配置**已在库** (`modules/services/default.nix:15` = `["nixmeow.miku-garibaldi.ts.net"]`), 但系统级 `dsh-fence.service` 当前 `inactive/dead` — 配置是死路径喵~
2. 3080 端口实际由 **repo 外的 user 单元 `~/.config/systemd/user/dsh-web.service`** 承载 (ExecStart 无 `--trusted-host` 参数)喵~
3. 沙箱内对 Tailscale IP 的 TLS 探测被阻 (HTTP 000/exit 35), 无法远程验证 403 是否仍复现喵~
4. 后续若要落实: 把 dsh-web 纳入 fence/trusted-host 管理属**服务迁移**, 动 dsh-web 可能中断活跃 AI 会话 (含执行本操作的会话本身), 必须用户在场决策喵~ 原 403 若仍复现, 建议给 user 单元补 `--trusted-host nixmeow.miku-garibaldi.ts.net` 后重启验证喵~

## 关联上下文

- 用户之前尝试过：`tailscale set --ssh`（已成功启用 SSH）
- Tailscale 主机名：`NixMEOW`，IP：`100.126.4.97`，DNS：`nixmeow.miku-garibaldi.ts.net`
- DSH 绑定到 `127.0.0.1:3080`（仅回环），通过 Tailscale 代理转发
