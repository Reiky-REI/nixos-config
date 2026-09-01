---
date: 2026-09-01
module: modules/services/default.nix, home/Reiky-REI/default.nix, home/Reiky-REI/desktop/niri/sections/base.kdl, ~/.config/noctalia/settings.json
tags: [blackscreen, suspend, noctalia, idle, amdgpu, wake-failure, systemd-sleep, agent-resume]
layer: desktop
severity: high
related:
  - ../known-issues.md (2026-08-17 睡眠唤醒黑屏 / 2026-08-18 amdgpu 唤醒竞态条目)
  - 2026-08-17-niri-pin-old-rev.md (同期桌面稳定性排查)
  - 2026-08-31-data-loss-incident.md (同日磁盘满 → journald 停摆造成日志空洞的间接背景)
experience:
  - "挂起类黑屏定案手筋: journal 尾部 suspend entry 无 exit = 唤醒失败实锤, 不用再怀疑合成器喵~"
  - "无日志时段 (磁盘满 journald 停摆) 的崩溃, 可用 idle-30min 挂起节律反推时间线定案喵~"
  - "改运行时 settings.json 前先杀对应进程防退出回写, 改完手动重启该服务喵~"
  - "systemd.sleep.settings.Sleep.AllowSuspend=no 是可逆保险丝, 比追唤醒 bug 更稳; 休眠 S4 路径独立, 可另行实测喵~"
  - "本机 sudo setuid 在 AI 会话沙箱与 systemd user 单元里均被剥; root 操作走系统级 systemd-run (polkit 对活跃本地会话放行)喵~"
  - "管道 | tail 会吃退出码造成假 OK; systemd 单元 stdout 进 journal 不进调用方, 关键任务输出必须文件重定向喵~"
---

# 复盘: noctalia idle 自动挂起 × S3 唤醒必坏 → 一天三连黑屏强重启

## 背景
用户深夜报告"突然黑屏, 不得不强制重启"喵, 且下午 15:41~16:02 也有一次同款崩溃喵。要求定位根因并修复, 授权 switch + 保留最近 3 世代喵。

## 时间线 (证据链)
| 时间 | 事件 | 证据 |
|------|------|------|
| 8-31 13:19 | rclone vfs 缓存吃满磁盘, journald 停摆 | `no space left on device`, 此后日志真空 |
| 8-31 ~16:00 | 第一次崩溃 (用户报告 15:41~16:02 之间) | 无日志 (磁盘满), 与 idle-30min 节律吻合 |
| 8-31 19:53:41 | 第二次: 闲置 30 分钟自动挂起 | boot -2 尾部 `PM: suspend entry (deep)` 无 exit |
| 8-31 19:59:02 | 用户强制重启 | boot -1 开始 |
| 9-1 01:34:31 | 第三次: 同款自动挂起 | boot -1 尾部 `PM: suspend entry (deep)` 无 exit |
| 9-1 01:35:20 | 用户强制重启 | 当前 boot |

挂起前无 logind Lid/PowerKey 事件, logind.conf 无 IdleAction, swayidle 早已崩溃退出 (见下) → 排除系统侧触发源喵。

## 根因 (两因叠加)
1. **触发源**: noctalia-shell 内置 idle 管理 `settings.json: idle.enabled=true, suspendTimeout=1800` → 闲置 30 分钟自动 `systemctl suspend` 喵。历史注释 (modules/services/default.nix) 显示"之前为防 Noctalia 待机挂起失败曾禁用 AllowSuspend", 后来重开 suspend 时**漏关了 noctalia 的 idle 挂起**, 埋雷喵。
2. **故障态**: amdgpu + NVIDIA PRIME 深挂起唤醒必坏 (8-17 已实锤, 8-18 定位 amdgpu 7.x 唤醒竞态家族, 7.1.5 pin 后一直"待实测"——本次三连即实测结果: 未修复) 喵。挂起 = 必黑屏 = 必强刷喵。

## 修复 (双保险 + 陷阱清理)
1. **掐触发源** (运行时 `~/.config/noctalia/settings.json`, 不入库, 备份 /tmp/noctalia-settings.json.bak-blackscreen-fix-20260901):
   - `idle.suspendTimeout: 1800 → 0` (息屏 screenOffTimeout=600 保留, DPMS 息屏安全喵)
   - 会话菜单 suspend 电源按钮 `enabled: true → false` (休眠按钮保留)
   - 操作顺序: 先 kill noctalia (防退出回写) → 改文件 → 重新拉起 ✓
2. **封死 S3 故障态** (声明式, 入库): `modules/services/default.nix` → `systemd.sleep.settings.Sleep.AllowSuspend = "no"`, 任何路径 (合盖/键bind/应用) 均无法进入挂起喵。
3. **Super+L 陷阱键清理**: `home/Reiky-REI/desktop/niri/sections/base.kdl` 原为 `hyprlock + systemctl suspend` (一按必黑屏强刷), 改纯 `hyprlock` 锁屏喵。
4. **swayidle 崩溃循环顺手修**: HM `services.swayidle.enable = true` 但零 event → 空配置秒退 → start-limit-hit, 且与 noctalia idle 功能重复 → `enable = false` 喵。

## 验证
- settings.json JSON 合法, 三值确认 ✓; noctalia 重启后稳定运行 (plugin 加载正常) ✓
- build: `nixos-rebuild build` 通过 (系统级 systemd-run 单元 nixbuild-blackscreen, REBUILD_EXIT=0) ✓
- switch 后待验证: `sudo nix env` AllowSuspend 生效 (`/etc/systemd/sleep.conf`), swayidle 单元消失, loader.conf default 三验喵
- idle 30 分钟不再自动挂起: 待用户日常使用观察喵

## 中途新问题 (顺手记录)
1. **agent-resume 队列假 OK**: runner 的 task log 只收 systemd-run 客户端输出, unit stdout 进 journal 收不到; payload 里 `| tail` 又把退出码吃成 0 → 构建失败也报 OK喵。已改用自带文件重定向的独立单元跑构建喵。runner 本体待修 (见 known-issues 新条目)。
2. **sudo setuid 全域不可用**: AI 会话沙箱和 systemd user 单元里 sudo 均报 "must be owned by uid 0 and have the setuid bit set"; 正解 = 系统级 systemd-run (polkit 对活跃本地会话放行, unit 直接以 root 跑, 8-30 复盘已有先例)喵。
3. **会话环境 PATH 被重置**: 权限策略切换后 bash PATH 只剩两个用户目录, 每条命令前需 `export PATH=/run/current-system/sw/bin:...` (transient, 未入库)喵。

## 遗留
- 悬而未决申请 2 条 (`requests/pending/`): wifi-fixed-pending-reboot / dsh-fence-trusted-host, 本次顺带处理归档喵。
- 损坏 refs (refs/heads/feat, refs/heads/test_write_ref) 与已合并的 archive-extract 本地分支待清理喵。
- 00:29:15 niri compositor 重启一次 ( Lost connection) 原因未查, 无伴随崩溃日志, 疑用户手动重启, 挂起疑云解除后暂不追喵。
- 唤醒修复的正道: 等上游 amdgpu 修复; 或实测 S4 休眠 (路径独立, AllowHibernation 现为 no, 需另评 swap/内核参数) 喵。

## 追记 (19:38): noctalia 亮度失灵修复
凌晨由 bash 裸环境拉起的 noctalia (46311) 实际一直是唯一实例且缺会话环境 → 亮度调节失效喵。
且 07:52 复核时 `pgrep -f quickshell` 空输出是**显示截断假象**, 被误判为"未运行", 后来批处理里的 `pgrep -f quickshell && echo ✓` 又匹配到自己 bash -c 命令行造成假阳性喵——**pgrep -f 自匹配正反两面都是坑**, 判进程生死必须 `ps -eo args | grep -v grep` 级别确认喵。
修复: `niri msg action spawn -- noctalia-shell` (NIRI_SOCKET=$XDG_RUNTIME_DIR/niri.<display>.<pid>.sock) 以正规 systemd user scope 拉起 (app-niri-noctalia-shell.scope, PPID=user manager, 环境完整) → 击毙裸环境实例 (精确 pid) 喵。
底层背光同步实测: brightnessctl --class=backlight set 30% 生效 (1→18735), 硬件通道无损喵。
