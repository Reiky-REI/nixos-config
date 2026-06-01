---
date: 2026-06-01
module: modules/networking/default.nix
tags: [dns, tailscale, systemd-resolved, networking]
layer: networking
severity: medium
related:
  - ../known-issues.md
experience:
  - "Tailscale MagicDNS (100.100.100.100) 转发到路由器 DNS 时无 fallback，单点依赖导致间歇性 DNS 失败"
  - "启用 systemd-resolved 后 Tailscale 自动用 resolvectl 配置 DNS，无需改 tailscale.nix"
  - "systemd-resolved 的 fallbackDns 提供自动故障转移，解决了 resolvconf 时代无 fallback 的问题"
---

## 背景

`git push` 报 `ssh: Could not resolve hostname github.com: Temporary failure in name resolution`

## 诊断

1. `/etc/resolv.conf` 仅 `nameserver 100.100.100.100`（Tailscale MagicDNS），无 fallback
2. Tailscale 上游 DNS 转发到路由器 `192.168.1.1`，间歇性超时（tailscaled 日志确认）
3. 非 HTTP 流量（SSH/git）无法享受 Clash 代理的 DNS 代理，直接受系统 DNS 影响

## 修复

在 `modules/networking/default.nix` 添加 systemd-resolved 配置：

```nix
services.resolved = {
  enable = true;
  fallbackDns = [ "1.1.1.1" "8.8.8.8" ];
};
```

NixOS resolved 模块自动：
- `/etc/resolv.conf` → symlink 到 `127.0.0.53`（systemd-resolved stub）
- `networking.networkmanager.dns = "systemd-resolved"`
- `networking.resolvconf.package = pkgs.systemd`

Tailscale 自动检测 systemd-resolved，使用 `resolvectl` 配置 DNS 而非直接写 resolv.conf。

## DNS 架构变化

**旧**: `程序 → resolvconf → 100.100.100.100 → 192.168.1.1`（单点，无 fallback）

**新**: `程序 → 127.0.0.53 (systemd-resolved)`
- `ts.net` 域名 → tailscale0 → 100.100.100.100（MagicDNS）
- 其他域名 → wlp4s0 → 192.168.1.1（路由器 DHCP DNS）
- 路由器 DNS 超时 → fallbackDns（1.1.1.1, 8.8.8.8）

## 教训

- Tailscale `--accept-dns` + resolvconf 时代，系统 DNS 完全依赖路由器，无 failover
- systemd-resolved 是 Linux DNS 管理的最佳实践，提供缓存、多上游、DNSSEC、自动故障转移
