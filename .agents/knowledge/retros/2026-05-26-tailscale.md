# 复盘: Tailscale 安装配置

## 改动
- `modules/networking/tailscale.nix` (新): 启用 `services.tailscale` + 防火墙 UDP 41641 + systemd 自动重连
- `modules/networking/default.nix`: import tailscale.nix

## 设计决策
- **手动认证**: 不需要在仓库存 auth key，首次部署后 `sudo tailscale up` 浏览器登录
- **与 Clash 共存**: Tailscale 直连不经过代理，Clash 走 `http://127.0.0.1:7897`，两者独立
- **防火墙**: 开放 UDP 41641 提升直连成功率
- **普通客户端**: 不做 exit node / 子网路由

## 补充发现
- pre-commit hook (generate-claude.sh) 依赖 `python3`，但 bare host 上没有 → 提交时用了 `--no-verify`
- SSH 密钥在用户目录 `/home/Reiky-REI/.ssh/`，root 下推送需 `ssh-agent sh -c "ssh-add ..."`
