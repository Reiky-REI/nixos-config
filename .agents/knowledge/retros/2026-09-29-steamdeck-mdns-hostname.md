---
date: 2026-09-29
module: modules/networking/default.nix
tags: [networking, avahi, mdns, ssh, steamdeck]
layer: networking
severity: low
related: []
experience:
  - "Steam Deck Avahi advertises `steamdeck.local`; NixMEOW needs mDNS NSS resolution to use it as an SSH destination喵~"
  - "SSH public-key authentication is independent of the host address; a stable hostname and SSH alias solve endpoint changes without changing credentials喵~"
---

# Steam Deck SSH 主机名解析

## 现场

- Deck 的 Avahi 广播主机名为 `steamdeck.local`，在 Deck 本机解析到当前 DHCP 地址喵~
- NixMEOW 的 WLAN 链路显示 systemd-resolved mDNS scope active，但 `getent` 与 `resolvectl query` 均无法解析 Deck 主机名喵~
- NixMEOW 已通过 SSH 公钥认证 Deck；连接使用 IP 是地址发现问题，不是凭据问题喵~

## 修复

- 对启用 NetworkManager 的 host 启用 Avahi、IPv4 mDNS NSS 和 mDNS 防火墙规则喵~
- NixMEOW 用户 SSH 配置新增 `steamdeck` alias，目标为 `steamdeck.local`，并沿用现有 Ed25519 身份认证喵~
- MAC 地址不直接用于 SSH；如果网络禁止 mDNS，应在路由器按 Deck WLAN MAC 建立 DHCP reservation 喵~

## 验证

- `nixos-rebuild build --flake /etc/nixos#NixMEOW` 通过喵~
- 构建后的 `nsswitch.conf` 包含 `mdns4_minimal [NOTFOUND=return]` 喵~
- 运行时主机名解析需在激活该 generation 后验证喵~
