---
date: 2026-08-16
module: home/Reiky-REI/tools/mihomo.nix
tags: [mihomo, proxy, systemd, clash-verge, external-controller, socket, ENOENT]
layer: home
severity: high
related:
  - ../known-issues.md (全局代理 mihomo 死亡 / 双开与控制器坑)
  - ../../dialogue/2026-08-16-002-opencode-to-claude-proxy-mihomo.md (headless 方案讨论)
experience:
  - "headless mihomo unit 与 Clash Verge GUI 共用同一份合并配置时会双开抢 unix socket;用 TCP 控制器 (-ext-ctl) + 统一端口 (9097) 让 GUI 能附着同一核心,而非各起一个。"
  - "合并配置里 external-controller: '' 是 GUI 未启用控制器的默认值,unit 侧用 -ext-ctl CLI 参数强制覆盖比改 GUI 配置文件更可靠。"
  - "systemd user unit 要防 crash-loop 停摆:Restart=always 撞上默认 StartLimit (5次/10s) 会被限流,双开抢端口场景要设 StartLimitIntervalSec=0。"
  - "verge-mihomo 冒烟验证法:复制合并配置改端口/清掉 external-controller-unix,临时起核心验证 -ext-ctl 生效 + 代理通,不碰在跑的 7897。"
---

## 背景

Clash Verge GUI 在 Wayland 下 GTK 失败/随会话死亡, 它托管的 mihomo 核心跟着消失,
而 NixOS `networking.proxy` 硬编码 `http://127.0.0.1:7897` → 全系统静默断网
(opencode API/nix/git 全挂)。此前已建 headless user unit (`home/Reiky-REI/tools/mihomo.nix`)
想摆脱 GUI, 但 unit 未实际生效且存在四个坑。

## 四个坑 (Claude Code 排查 + 本会话复核确认)

1. **双开抢 unix socket**: unit 与 GUI 各自起核心, 都要 `-ext-ctl-unix %t/.../verge-mihomo.sock` → `address already in use`。
2. **cache.db 权限**: 核心曾被 root 化属主 → `permission denied` (本次复核时已是 Reiky-REI, 属主问题已恢复)。
3. **全局代理硬编码**: `127.0.0.1:7897` 写死在 NixOS 配置, mihomo 一死全断。
4. **external-controller 被清空**: `verge.yaml` 里 `enable_external_controller: false` → 合并配置 `clash-verge.yaml` 的 `external-controller: ''` → 核心无 TCP 控制器。

## 修复 (只 build, 未 switch)

### `home/Reiky-REI/tools/mihomo.nix` — 加固 unit
- 弃用 `-ext-ctl-unix`, 改 `-ext-ctl 127.0.0.1:9097` (TCP 控制器, 不再抢 unix socket)。
- `ExecStartPre`: `mkdir -p %t/clash-verge-rev` + `rm -f %t/clash-verge-rev/verge-mihomo.sock` (清理遗留 socket)。
- `Unit.StartLimitIntervalSec = 0`: 与 GUI 并存抢端口时持续重试, 不因默认 5次/10s 限流停摆。

### `~/.local/share/.../verge.yaml` — 补 TCP 控制器
- 加 `external-controller: 127.0.0.1:9097`, `enable_external_controller: true`。
- 目的: GUI 之后打开时走 9097 附着同一核心, 而不是再 spawn 一个 (混口 7897 也抢)。

## 验证

- 端口实况: 9097/9090 空闲, 7897 被 GUI 核心占用; cache.db 已 Reiky-REI 属主。
- **冒烟测试** (安全副本配置): 复制合并配置改 mixed-port→7898、清 external-controller-unix,
  用 unit 同款命令 `-ext-ctl 127.0.0.1:9097` 起核心:
  - TCP 控制器 `127.0.0.1:9097` 监听并响应 (返回 Unauthorized=有 secret, 证明 -ext-ctl 覆盖了空 external-controller);
  - 代理 `curl --proxy http://127.0.0.1:7898 https://www.gstatic.com/generate_204` → HTTP 204。
  - 测试后 kill, 端口释放。
- `nixos-rebuild build --flake /etc/nixos#NixMEOW` 通过;
  生成的 user unit 确认含 `-ext-ctl 127.0.0.1:9097` + rm socket + `StartLimitIntervalSec=0`。
- 注: flake 要求引用的文件被 git 追踪, untracked 的 mihomo.nix 需 `git add` 才能 build。

## 待用户/Claude 执行 (switch 后)

```bash
# 1) 停 GUI 核心 (双开清理)
pkill -f verge-mihomo; pkill -f clash-verge
# 2) switch 使 unit 生效 (注意 AGENTS.md 的 PRIME 崩溃风险, 由用户决定)
sudo nixos-rebuild switch --flake /etc/nixos#NixMEOW
# 3) 启用 headless unit 并验证
systemctl --user daemon-reload && systemctl --user enable --now mihomo
ss -tlnp | grep -E '7897|9097'            # *:7897 + 127.0.0.1:9097
curl -m5 --noproxy '*' http://127.0.0.1:9097/version   # 有 secret 会 Unauthorized, 但端口通
curl -m8 --proxy http://127.0.0.1:7897 -o /dev/null -w '%{http_code}\n' https://www.gstatic.com/generate_204
```

## 追加: switch 落地 + 两个新坑 (2026-08-16)

首次 switch 失败: home-manager 解析生成的 unit 报
`expected entry key name but got '/' at line 10`。根因是 ExecStartPre 写成多行块字符串,
home-manager 序列化时丢了续行缩进, `rm` 行顶到行首被当成新键。
修复: 改用列表 `ExecStartPre = [ "mkdir..." "rm..." ]` → 生成两条独立 `ExecStartPre=` 行。

第二次 switch 成功 (gen 165)。但 unit 持续 crash-loop: `rm: Permission denied`。
根因: `/run/user/1002/clash-verge-rev/` 目录 + socket 是 root 进程 (clash-verge-service) 在 01:58 留下的
`root:root` 残留, user unit 无法 rm/建 socket。一次性清理 (chown 目录 + rm socket) 后,
pkill 掉 GUI 核心 (双开), unit 干净接管 `*:7897` + `127.0.0.1:9097`。

**验收 (全部实测通过):**
- `systemctl --user is-active mihomo` = active, MainPID 持有 7897+9097;
- 代理 `curl --proxy 127.0.0.1:7897 gstatic/generate_204` = 204;
- TCP 控制器 `curl -H "Authorization: Bearer set-your-secret" 127.0.0.1:9097/version` = `{"version":"1.19.24"}`;
- root clash-verge-service 已 kill。

**顺带**: dsh-fence 的 PATH 修复 (commit 0a61757) 在第一次 (半失败的) switch 里就随系统单元激活生效
(home-manager 失败不影响系统单元), DSH bash 工具已可用 —
实测用 DSH 进程同款 PATH `spawn("bash")` 输出 `DSH-BASH-OK`, `which bash` = `/run/current-system/sw/bin/bash`。

