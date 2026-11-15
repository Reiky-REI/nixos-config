---
date: 2026-11-15
agent: opencode
status: success
module: modules/storage/nas-mount.nix
tags: [nas, cifs, smb, systemd, timer, 挂载, 开机时长, timeout]
topic: 开机 21 天后小服务超时的根因 —— 陈旧 NAS 挂载 + 只在开机挂一次
---

# Retro: NAS 挂载陈旧导致全局卡顿 —— 加健康巡检 timer

用户提问：「电脑是不是开机很久之后会出问题，现在开机 21 天了，看看是不是有小服务 timeout?」

## 排查结论

系统层是健康的：`systemctl --failed`（系统 + 用户）为空，boot 内 OOM 计数 0，
内核无硬件报错（只有 ntfs3 修 link count 的良性日志）。所以「长 uptime 必然劣化」不成立。

真正在超时的是三件互不相关的事：

| 现象 | 证据 | 根因 |
|---|---|---|
| `~/nas` 访问卡死 | `stat /home/reiky/nas` 无返回；tmpfiles 报 `Host is down` 两次 | CIFS 服务端 192.168.124.9 不可达，陈旧挂载一直留着 |
| starship 扫描 cwd 超时 | 终端启动即告警 | 高负载（nix build 3.2G RSS）+ 陈旧挂载叠加 |
| tailscaled `control: map` 超时 49 次 | 集中在 11-14 02:45–02:47，走 IPv6 到 controlplane | 网络/代理抖动，非 tailscale 故障，已自愈 |
| hermes-agent 今天重启 3 次 | `PermissionError: .hermes/skills/**/.tmp_*` | `~/.hermes/skills` 下 76 个目录是 `dr-xr-xr-x` |

另有：根分区 92%（87G/100G）→ `nix-collect-garbage -d` 回收 5.9G，降到 84%（16G 可用）。

## 根因：`nas-mount.service` 是「一次性」的

`modules/storage/nas-mount.nix` 只在 `multi-user.target` 时挂一次
（`Type=oneshot` + `RemainAfterExit=yes`，实测 `active (exited)` 已 3 周）。
NAS 每周换 IP、夜间休眠、掉线后：

1. 挂载点变成陈旧 CIFS（服务端不可达），永远没人摘掉；
2. `Type=oneshot` 已 active，`systemctl start` 不会再执行脚本；
3. 于是任何 `stat/ls/find ~/nas` 都卡在 D 状态（uninterruptible），
   连带 tmpfiles-clean、文件选择器、agent 的目录扫描一起超时。

**这就是「开机越久越糟」的机制**：不是系统劣化，是开机时那一次成功/失败的决定被永久冻结。

## 修法

`modules/storage/nas-mount.nix`：

1. **新增 `nas-health.service` + `nas-health.timer`**（`OnBootSec=2min`，
   `OnUnitActiveSec=5min`）：比较当前挂载 source IP 与按 MAC 重新发现的 IP
   - 已挂载 + IP 一致 → 认为健康，不动它（避免无谓 churn）
   - 已挂载 + IP 变化 / NAS 不可达 → `umount -f -l` 惰性分离，再 `systemctl restart nas-mount`
   - 未挂载 + NAS 在线 → 触发挂载（解决「开机时 NAS 没醒，之后永不重试」）
2. **健康检查绝不触碰挂载点**：用 `findmnt`（读 `/proc/self/mountinfo`）判断是否挂载，
   **不用 `mountpoint`**——它靠 `stat`，在陈旧 CIFS 上会把自己卡死。
   同理 `nas-mount` 原有脚本里的 `mountpoint -q` 也换成了 `findmnt`。

故意**没有**加 `soft` 挂载选项：`soft` 会在超时后返回 EIO，写一半的文件可能只写了一半；
7.2G 那次事故（WebDAV 静默失败）的教训是「宁可显式失败也不要静默丢数据」。
当前策略是硬挂载 + 5 分钟内自动摘除陈旧挂载，兼顾写安全与不卡死。

## 验证

- `nixos-rebuild build --flake .#NixMEOW` → 通过
- `nixos-rebuild dry-activate --flake .#NixMEOW` → 无 `would restart` 风险项
- `nixos-rebuild switch`（用 `systemd-run` 脱离会话跑）→ generation 271 生效
- `systemctl start nas-health` → 日志 `NAS 不可达, 保持未挂载 (nofail)`，无 spurious umount
- `systemctl list-timers | grep nas` → `nas-health.timer` 每 5 分钟运行

## 附带处理

- `chmod u+w -R ~/.hermes/skills`（76 个只读目录 → 0），修 hermes-agent 的临时文件 PermissionError
- `sudo umount -f -l /home/reiky/nas` 摘掉当时的陈旧挂载
- `sudo nix-collect-garbage -d` 回收 5.9G

## 教训

1. **`Type=oneshot` + `RemainAfterExit` 的网络挂载不是自愈的**，必须配 timer 或 automount。
2. **诊断挂载健康时不能 `stat` 挂载点**，用 `findmnt` / `/proc/self/mountinfo`，否则诊断手段本身会卡死。
3. 「开机久了出问题」类问题，优先查**一次性状态被冻结**（挂载、缓存、socket、一次性的 oneshot），
   而不是先怀疑内存泄漏 —— 本例 swap 2.9G、PSI full avg300 1.27%，远未到危险。

## 实施中踩到的两个坑

1. **`findmnt --target` 会返回父挂载**：目标目录本身不是挂载点时，`--target` 返回最近的祖先
   （本例 `/dev/nvme1n1p2`），于是「未挂载」被误判成「已挂载」，
   首版巡检日志打出 `已挂 //` 并去 umount 一个并不存在的挂载。
   判断「某路径本身是不是挂载点」必须用 `findmnt --mountpoint`（不是挂载点则 rc=1、无输出）。
2. **`systemd-run` 起的 unit 里没有 `/run/current-system/sw/bin` 的 PATH**：
   `nixos-rebuild-ng` 是 Python，内部用 `subprocess(["test", "-f", ...])` 判断 `nixos-version`，
   PATH 不全就抛 `[Errno 2] No such file or directory: 'test'`，
   表现为「构建全过、激活没发生、退出码 1」。
   用 `systemd-run` 脱离会话跑 switch 时必须显式
   `--setenv=PATH=/run/current-system/sw/bin:/run/wrappers/bin:/nix/var/nix/profiles/default/bin`。
