---
name: dsh
description: DSH (DeepSeek Harness) 服务管理 — 启停/排障/Tailscale 远程/端口冲突
agents: [opencode, claude]
---

## Root 通道 (sandbox 内执行 sudo)

sandbox 有 `NoNewPrivs=1` 限制, `sudo` 不可用。用 `systemd-run` 绕过:

```bash
# 基本格式
systemd-run --unit=<唯一名称> --uid=0 --gid=0 \
  --property=Environment="PATH=/run/current-system/sw/bin:/nix/store/5kcc5rnag7yymmsr6yqs7993xpdqs62w-coreutils-9.11/bin" \
  /run/current-system/sw/bin/bash -c "<命令>"

# 示例: 启动 dsh-fence
systemd-run --unit=dsh-start --uid=0 --gid=0 \
  --property=Environment="PATH=/run/current-system/sw/bin" \
  /run/current-system/sw/bin/bash -c "systemctl start dsh-fence"

# 查看输出
journalctl -u <unit-name> --no-pager
```

**注意**: 每个 unit-name 必须唯一, 用完可 `systemctl stop <unit>` 清理。
需要 NixOS 里配了 `security.polkit.extraConfig` (wheel 组免密) 才能不弹密码。

## ⚠️ 重要: 不要杀自己的进程!

- `pkill -f dsh` 会匹配到 agent 自身的 node 进程 → **绝对禁止**
- `kill` 只能操作精确 PID，先 `ps aux | grep dsh` 确认目标再操作
- DSH 相关进程: `dsh-fence.service` (systemd) / `dsh-tui` (手动终端)
- **手动 dsh-tui 不要杀** — 它是用户在终端里运行的交互会话

## 架构概览

```
Tailscale 客户端
  ↓ HTTPS/HTTP
tailscaled (监听 100.126.4.97:3080/443)
  ↓ proxy
localhost:3080
  ↑ 监听
dsh-fence.service (systemd, User=Reiky-REI)
```

## 服务管理

### 查看状态
```bash
systemctl status dsh-fence
systemctl is-enabled dsh-fence
```

### 启动/停止/重启
```bash
# 启动 (需要 root)
sudo systemctl start dsh-fence

# 停止
sudo systemctl stop dsh-fence

# 重启
sudo systemctl restart dsh-fence

# 查看日志
journalctl -u dsh-fence -f
```

### 端口检查
```bash
# 检查 localhost:3080 是否有人监听
ss -tlnp | grep 3080

# 检查 127.0.0.1:3080 (dsh-fence)
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3080/

# 检查 tailscale serve (绕过 Clash 代理!)
curl -s --noproxy '*' -o /dev/null -w "%{http_code}" http://nixmeow.miku-garibaldi.ts.net:3080/
curl -sk --noproxy '*' -o /dev/null -w "%{http_code}" https://nixmeow.miku-garibaldi.ts.net/
```

## Tailscale 远程访问

### 配置
- Tailscale serve: `http://nixmeow.miku-garibaldi.ts.net:3080` → `localhost:3080`
- Tailscale serve HTTPS: `https://nixmeow.miku-garibaldi.ts.net` → `localhost:3080`
- trusted-hosts: `nixmeow.miku-garibaldi.ts.net` (在 `modules/services/default.nix` 设置)

### 管理
```bash
# 查看 tailscale serve 状态
tailscale serve status

# 重新配置 (一般不需要, 已在 NixOS 配置里固定)
tailscale serve https+insecure://localhost:3080
```

## 端口冲突排查

### 问题: dsh-fence 启动失败 (EADDRINUSE)
```bash
# 谁占了 3080?
ss -tlnp | grep 3080
# 如果是 tailscaled (pid=xxx) → 正常, 它是 Tailscale 代理
# 如果是 node 进程 → 手动 dsh 占了端口, 需要停掉

# 常见情况:
# tailscaled 监听 Tailscale IP:3080 → 正常, 不冲突
# dsh-fence 监听 127.0.0.1:3080 → 正常
# 如果两者冲突 → 检查 dsh-fence 是否重复启动
```

### 问题: Tailscale 远程 502/000
```bash
# 1. 检查 dsh-fence 是否在跑
systemctl status dsh-fence

# 2. 检查 localhost:3080 是否通
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3080/

# 3. 绕过 Clash 代理测试 tailscale
curl -s --noproxy '*' -o /dev/null -w "%{http_code}" http://nixmeow.miku-garibaldi.ts.net:3080/

# 4. 如果 3 步都正常但浏览器打不开 → 检查 no_proxy 配置
#    Tailscale IP 段 100.64.0.0/10 和 *.ts.net 应在 no_proxy 中
```

### 问题: Clash 代理拦截 Tailscale 流量
```bash
# 检查当前 no_proxy
echo $no_proxy

# 应包含: localhost,127.0.0.1,::1,*.local,100.64.0.0/10,*.ts.net
# 配置位置: modules/networking/default.nix → networking.proxy.noProxy
```

## NixOS 配置位置

| 配置项 | 文件 |
|--------|------|
| dsh-fence 服务定义 | `modules/services/dsh-fence.nix` |
| dsh-fence 启用 + trustedHosts | `modules/services/default.nix` |
| Tailscale 依赖 | `modules/services/dsh-fence.nix` (after/requires) |
| 代理 + noProxy | `modules/networking/default.nix` |
| Tailscale 基础 | `modules/networking/tailscale.nix` |

## 开机自启链路

```
boot
  → tailscale.service (VPN 连接)
  → dsh-fence.service (after: network.target + tailscale.service)
    → ExecStart: node bin.js web --trusted-host nixmeow.miku-garibaldi.ts.net
  → tailscaled 监听 Tailscale IP:3080 → proxy localhost:3080
```

## ⚠️ NixOS rebuild 注意事项

- `nixos-rebuild switch` 前 **先停 dsh-fence**: `sudo systemctl stop dsh-fence`
  - 否则 switch 可能因端口冲突失败 (EADDRINUSE) 或产生半切换状态
- dsh-fence 由 systemd 接管后, **不要再手动 `dsh web`**
- 手动 `dsh-tui` 可以共存 (绑定不同地址), 但占端口时 dsh-fence 可能启动失败
