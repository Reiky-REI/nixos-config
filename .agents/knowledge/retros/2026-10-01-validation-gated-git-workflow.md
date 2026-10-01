---
date: 2026-10-01
module: .agents/AGENTS.md, .agents/knowledge/conventions.md, .agents/skills/nixos-manager/SKILL.md, .agents/config/commit.sh
tags: [git, validation, stash, commit, workflow, collaboration]
layer: common
severity: low
related: []
experience:
  - "验证门禁决定改动是否可 commit,依赖关系与原子复用边界决定 commit 粒度喵~"
  - "stash 是未验证工作的可恢复检查点,只保存本任务文件且无需额外授权喵~"
  - "AI 先完成自动化验证,只有现场或硬件步骤无法替代时才交给用户喵~"
  - "commit message 与非显然代码注释应记录动机和取舍,帮助后续会话接续喵~"
  - "commit helper 必须显式推送当前 feature branch,不能固定推 main 或依赖隐式 upstream 喵~"
---

# 验证门禁与 Stash 检查点工作流

## 用户给出的规则

- 未通过验证的改动不进入 Git commit 喵~
- 验证失败时先修复并重跑喵~ 任务暂停、被阻塞或需要切换阶段时,可 stash 本任务文件且无需额外授权喵~
- stash 可以在重要修改前创建,也可以按需创建喵~
- 如果后续修改依赖前一步结果,或一个改动本身可独立复用,则分别验证并分别 commit 喵~
- 其他情形允许整批验证通过后做一个完整 commit 喵~
- AI 优先自行验证喵~ 只有现场 UI、硬件或其他无法自动化的步骤才交给用户喵~
- Git 记录与代码注释应表达关键思路、动机和取舍喵~

## 操作约定

- stash 使用描述明确的 task/module message 和路径限定喵,避免混入其他人的改动喵~
- 恢复 stash 使用 `git stash apply` 喵~ 保留 stash 直到改动验证通过并 commit 喵~
- bot commit helper 用 `HEAD:refs/heads/<current-branch>` 推送当前分支喵~
- commit 先写复盘再提交喵~ NixOS `switch` 的现有风险授权规则保持不变喵~
