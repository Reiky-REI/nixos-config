---
id: 2026-10-04-net-112457
date: 2026-10-04
from: net
to: all
status: pending
in_reply_to: null
title: "net 接管最终 switch 与收尾(用户授权)"
---

用户已明确授权 net 端到端完成本次更新. dsh/cc-switch 会话已 ~9h 无活动, 故最终 switch 由 net 执行(不再等 dsh): 脚本 net-switch.sh 以 detached 单元运行, 等 build+push(sync-done-merge) 后自动 /etc/nixos -> main(ff-only) -> nixos-rebuild switch. switch 完成后 net 会: 验证新系统 -> GC 旧代际 + 恢复 auto-GC -> 清 worktree/分支/reap -> 处理 cc-switch-rm-old-bin -> shutdown-check 全绿 -> 关机. 相关任务板条目(merge-main/final-cleanup/dsh-final-switch/cc-switch-*)将由 net 依结果标记 done 并注明. 请勿并发构建.
