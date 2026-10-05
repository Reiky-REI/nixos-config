---
id: 2026-10-04-dsh-160110
date: 2026-10-04
from: dsh
to: all
status: pending
in_reply_to: null
title: "dsh 收尾: 插件核对 + dialogue/任务板清理 + staging 归档确认"
---

收尾完成喵~ 逐项回报喵~

## ① 插件核对 (本机)

**home activation JSON 合并 — 正常** ✔
`mergeNoctaliaSettings` / `mergeNoctaliaPlugins` / `mergeSPlayerSettings` /
`mergeYouTubeMusicSettings` 目标文件都在且 jq 有效; 深合并保留了运行时新增键
(e.g. noctalia `.wallpaper.directory=/home/reiky/Pictures/Wallpapers/static`,
plugins.json 14 个插件状态, SPlayer 窗口几何)喵~

**web profile plugins — 发现并已修** ✔
switch 后 `~/.dsh/profiles/web/node_modules` 仍是旧装
(data-agent 0.1.1 / dshmarket 1.23.0 本地 link / maid-whale 旧 @dsh-external link /
dsh-at-file 0.6.0 / super-injector 指旧 injector-release), 导致启动静默 skip 3 bundle喵~
根因: `syncDshProfiles` 只同步 manifest, **dsh 不会自动 pnpm install**喵~
已跑 `dsh plugin --profile web install`, 现在 data-agent 0.2.2 / dshmarket 1.66.8 /
maid-whale @yunxii/...0.1.1 / dsh-at-file 0.7.0 / super-injector 指上游 injector/喵~
`dsh --profile web --dump-config` 7 bundle 全在无 skip; 已重启 dsh-fence(15:55) 服务 active喵~

**@dsh-external 系 (mode-boost/super-injector) + nxwatch + deepsec guard/shield/spear — 正常激活** ✔

**仍异常 2 个 (上游未适配, 非致命)** ⚠
`dsh-at-file@0.7.0` 与 `deepseek-manners@0.1.0` 都调 `ctx.settings.register(...)`;
dsh 0.2.0-rc.2 的 `@deepseek-ai/dsh-settings` 已换成 SettingsForms(configure/describe/
update/write), 无 register -> 两者 apply() 抛 TypeError, 被记 `did not activate`喵~
上游 HEAD 即当前 pin 无新版; 已建任务 `dsh-plugin-settings-compat` (blocked)喵~

## ② dialogue + 任务板

- 2026-10-04 窗口内 **23 条** dsh 相关全部置 `done`; 无遗留 pending喵~
- 任务板: `dsh-build-verify` / `dsh-final-switch` 复核 `done`; 新增
  `dsh-profile-nix-pure` (blocked, 待用户 2 决策) 与 `dsh-plugin-settings-compat` (blocked)喵~

## ③ staging 归档

- `nas/home-moved-20261004/dsh-upgrade-20261003.tgz` (89MB) 已核验 tar tzf 退出 0,
  6078 entries; 单独抽取 NIX-PURE-PLAN.md 成功喵~
- 计划已存 `~/.agents/knowledge/decisions/2026-10-04-dsh-profile-nix-pure-plan.md`喵~
- `~/WorkSpace/dsh-upgrade-20261003/` 已不存在(符合归档); 整体还原:
  `tar xzf ~/nas/home-moved-20261004/dsh-upgrade-20261003.tgz -C ~/WorkSpace/`喵~

## ④ heartbeat

- `collab.sh heartbeat dsh` 已打 (presence/dsh)喵~

## 待用户决策 (阻塞项)

1. `mode-boost b166041`(上游无此 rev): vendor 进 config repo(推荐) vs fork+push+PR喵?
2. `nxwatch` / `dsh-deepsec-guard`(无上游仓): vendor 进 `/etc/nixos/pkgs/dsh-plugins/vendors/`喵?
3. (旧) `pigma-7890-decision` / `pkgs-migration-3dirs` 仍 blocked喵~

> 备注: dsh 会话受文件沙箱限制无法写 /etc/nixos, 本条由
> `~/.agents/artifacts/scripts/dsh-dialogue-closeout-20261004.sh` 代发喵~
