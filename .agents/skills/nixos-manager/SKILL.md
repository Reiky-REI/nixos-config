---
name: nixos-manager
description: 安全管理 NixOS 配置，包括文件编辑、git 操作、nixos-rebuild 试运行等。
---

# NixOS 配置管理技能

当用户要求修改 NixOS 配置时，请严格遵循以下工作流：

## 1. 修改前准备
- 运行 `git status` 确保工作区干净
- 如果存在未提交变更，先询问用户是否提交或暂存

## 2. 编辑配置文件
- 使用 `read` 工具读取现有配置（如 `/etc/nixos/configuration.nix` 或 flake 中的相关文件）
- 使用 `edit` 工具进行修改，**必须提供清晰的 diff 说明**

## 3. 验证配置
- 执行 `nixos-rebuild build --flake .#<hostname>` 仅构建，不应用
- 如果构建失败，分析错误并回滚修改
- 执行 `nixos-rebuild test --flake .#<hostname>` 临时测试（可选）

## 4. Git 提交
- 生成符合 Conventional Commits 的提交信息，格式：`nixos(config): 修改说明`
- 提交前让用户确认变更内容

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
