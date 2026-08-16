---
date: 2026-08-16
module: modules/services/dsh-fence.nix
tags: [dsh, systemd, PATH, bash, ENOENT, harness]
layer: services
severity: high
related:
  - ../../known-issues.md (systemd 服务默认 PATH 缺 /run/current-system/sw/bin)
  - ../../../docs/HANDOFF.md (bash 工具全线 ENOENT 事故)
experience:
  - "NixOS systemd 服务默认 PATH 只有 coreutils/findutils/grep/sed/systemd,没有 /run/current-system/sw/bin。服务里 spawn 裸命令名(如 bash)会直接 ENOENT。"
  - "DSH bash 工具走 dsh-subprocess-local -> childEnv -> scrubbedParentEnv(),继承宿主服务进程的 PATH;宿主 PATH 缺 bash 就全线 ENOENT。文件工具(read/glob/write)不 spawn 进程所以不受影响——这是定位线索。"
  - "systemd 服务要给进程补 PATH 用 systemd.services.<name>.path 选项(listOf [package str]),比手写 serviceConfig.environment.PATH 更符合 NixOS 约定,且会拼上默认基础包。"
---

## 症状

DSH (deepseek harness, v0.1.0-rc.6) 的 bash 工具全线 `spawn bash ENOENT`,稳定复现;read/glob/grep/write 文件工具正常。

## 定位

DSH 由加固服务 `dsh-fence.service` 托管 (systemd, `User=Reiky-REI`)。

检查 `/proc/<dsh_pid>/environ`:PATH 是 NixOS systemd 服务默认的极简集合
(`coreutils/findutils/gnugrep/gnused/systemd` 的 store bin),**不含 `/run/current-system/sw/bin`**。

DSH bash 工具执行链:`dsh-bash-local` -> `ctx.subprocess.spawn(["bash","-c",cmd])`
-> `dsh-subprocess-local` 的 `childEnv` = `scrubbedParentEnv()`(保留宿主 PATH)
-> Node `child_process.spawn` 用该 PATH 解析 `bash` -> 找不到 -> ENOENT。

文件工具不 spawn 进程,所以不受影响 —— 这解释了"只有 shell 类操作挂掉"。

用宿主同款极简 PATH 在 node 里 `spawn("bash")` 复现 ENOENT,加上
`/run/current-system/sw/bin` 后正常,100% 确认根因。

## 修复

`modules/services/dsh-fence.nix` 给 `systemd.services.dsh-fence` 增加:

```nix
path = ["/run/current-system/sw"];
```

`path` 选项(listOf [package str])生成
`environment.PATH = /run/current-system/sw/bin:...默认基础包...`,
把整个系统包集合(含 bash/nixos-rebuild/git/systemctl/just)挂进服务 PATH,
同时保留围栏其余加固(只读 FS/零能力/网络收窄)不动。

## 验证

- `nix eval --raw .#nixosConfigurations.NixMEOW.config.systemd.services.dsh-fence.environment.PATH`
  首位已是 `/run/current-system/sw/bin`。
- `nixos-rebuild build --flake /etc/nixos#NixMEOW` 通过,
  生成的 unit 内 `Environment="PATH=/run/current-system/sw/bin:..."`。

## 待用户执行

`nixos-rebuild switch` 后 `systemctl restart dsh-fence`,DSH bash 工具即恢复。
(switch 有 NVIDIA PRIME 崩溃风险,未主动执行。)
