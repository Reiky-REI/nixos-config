---
date: 2026-09-19
module: modules/services/dsh-fence.nix
tags: [dsh-fence, tailscale, systemd, switch, 端口冲突]
layer: services
severity: medium
related:
  - ../known-issues.md (3080 端口冲突半切换章节)
  - ../../skills/dsh/SKILL.md (端口冲突排查)
experience:
  - "Requires= 指向不存在的单元不会在 build/eval 阶段报错, 只在 start 时失败 — systemd 依赖悬空是构建盲区, 加服务前用 systemctl cat 核对真实单元名"
  - "nixpkgs services.tailscale.enable 生成的单元叫 tailscaled.service, 不是 tailscale.service"
  - "switch 前的 3080 端口检查真正要查的是手动 dsh 进程, 而它的存在根源就是 dsh-fence 从未随开机启动"
---

# dsh-fence 依赖悬空 tailscale.service 修复实录

## 现象
switch 前按铁律检查 3080 端口, 发现 `127.0.0.1:3080` 被 pid 1753 (`node bin.js web --no-open`) 占用 — 用户手动跑的 dsh web喵~

## 根因
`dsh-fence.nix` (158de0c 引入) 写了 `after/requires = tailscale.service`喵~ nixpkgs 的 `services.tailscale.enable` 生成的是 **`tailscaled.service`**, `tailscale.service` 从不存在喵~ 悬空 `Requires=` 导致 dsh-fence 自创建以来从未随开机拉起, 用户只能手动 `dsh web`, 反过来又制造了 switch 半切换风险的正反馈喵~

## 修复
`after/requires` 改为 `tailscaled.service` (ea196f0), switch 后 `dsh-fence.service` 主动拉起, 本地与 Tailscale 远程均 200喵~

## 验证
- `systemctl is-active dsh-fence` → active
- `curl http://127.0.0.1:3080/` → 200
- `curl http://nixmeow.miku-garibaldi.ts.net:3080/` → 200 (绕代理)
