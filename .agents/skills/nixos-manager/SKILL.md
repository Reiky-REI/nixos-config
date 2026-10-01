---
name: nixos-manager
description: 安全管理 NixOS 配置，包括文件编辑、git 操作、nixos-rebuild 试运行等。
agents: [opencode, claude]
---

# NixOS 配置管理技能

当用户要求修改 NixOS 配置时，请严格遵循以下工作流：

## 1. 修改前准备
- 运行 `git status` 确保工作区干净
- 若有其他任务或其他人的未提交变更,不要暂存、覆盖或混入本任务喵~ 改用独立 worktree 或先确认归属喵~
- 本任务未验证改动可在每个重要修改前或按需 stash checkpoint 喵~ stash 无需额外用户授权喵~

## 2. 编辑配置文件
- 使用 `read` 工具读取现有配置（如 `/etc/nixos/configuration.nix` 或 flake 中的相关文件）
- 使用 `edit` 工具进行修改，**必须提供清晰的 diff 说明**

## 3. 验证配置
- 执行 `nixos-rebuild build --flake .#<hostname>` 仅构建，不应用
- 如果 build 失败喵,先分析并修复后重跑喵~ 无法通过、被阻塞或需要暂停时 stash 本任务改动,不得 commit 未验证内容喵~
- 执行 `nixos-rebuild test --flake .#<hostname>` 临时测试（可选）
- 后续修改依赖前一步结果时喵,或改动本身是可独立复用的原子单元时喵,分别 build/验证并分别 commit 喵~ 其他情况可整批验证通过后一次 commit 喵~
- 验证优先由 AI 完成喵~ 只有硬件、现场 UI 等无法远程验证时才交给用户喵~ 交接前 stash 未验证改动并给出恢复与验证步骤喵~

## 4. Git 提交
- 生成符合 Conventional Commits 的提交信息，格式：`nixos(config): 修改说明`
- 仅在所有必需 build/test 通过后 commit 喵~ 按项目 bot identity 和 commit helper 提交喵~ stash 无需额外授权喵~
- commit message 说明目标与关键原因喵,非显然代码注释记录约束和取舍喵~

## 5. 最终应用 ⚠️

**🚨 此系统有 NVIDIA PRIME 混合显示！switch 会崩 compositor！**
- `nixos-rebuild switch` 重启 `polkit.service` → compositor 失去 DRM master → 黑屏硬重启
- **AI 不得主动执行 `switch`**
- **AI 默认执行 `nixos-rebuild build`**，然后提示用户手动处理：
  - 内核未变 → 用户自己 `sudo nixos-rebuild switch`
  - 内核已变 → 用户应 `reboot`
- 如果用户明确要求立即生效并接受风险，可例外

## 安全限制
- **绝对不允许** 未经用户确认执行 `nixos-rebuild switch`（即使确认，也需详细说明崩溃风险）
- **绝对不允许** 直接删除 `/etc/nixos/` 下的文件
- **绝对不允许** 执行 `git push --force` 到 main 分支
