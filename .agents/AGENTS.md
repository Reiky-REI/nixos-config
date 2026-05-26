# NixMEOW Agent Guide

本仓库由 **OpenCode** 和 **Claude Code** 共同维护。以下约定两个 AI 都必须遵守。

## 快速命令
- dry-run: `sudo .agents/config/rebuild.sh`
- build: `sudo .agents/config/rebuild.sh build` (推荐)
- switch: `sudo .agents/config/rebuild.sh switch` (⚠️ NVIDIA PRIME 崩溃风险)
- 后台编译: `sudo systemd-run --unit=nix-rebuild ...` (详见 skill:rebuild)

## 知识体系
AI 工作纪律：
1. **instructions** 始终在 context: AGENTS.md + INDEX.md + conventions.md
2. 先读 **INDEX.md** → 按需读知识文件
3. 读 **INDEX.md** 中的 skill 清单 → 需要时加载 skill
4. 任务完成后写 **复盘** 到 retros/
5. 坑出现 2 次 → 提炼到 known-issues.md

## 多 AI 协作规则

### Git 工作流
1. **绝不直接在 main 上改** — 每个任务开一个 feature branch
2. **开工前检查** — `git status` + `git branch`，确认没有未提交变更或进行中的分支
3. **改完先 build** — `nixos-rebuild build --flake /etc/nixos#NixMEOW` 通过后再提交
4. **提交后推送分支** — 让另一个 AI 或用户来 merge 到 main
5. **复盘不可少** — 任何配置变更完成后写一条到 `retros/`

### 冲突预防
- 如果发现非自己创建的分支，先看看 `retros/` 里有没有对应说明再做
- 同一时间段尽量不碰同一模块文件

### 关于彼此
- OpenCode: AI coding assistant, 主配 `.agents/` 体系
- Claude Code: AI coding assistant (我), git 身份 `claude-code[bot]`
- 两者工具能力不同，但代码约定一致。详见下方「OpenCode 对齐方式」

### Claude Code 特有机制
- **Hooks 自动化**: Claude Code 支持 pre-commit/post-command hooks（定义在 `.claude/settings.json`）
  - PreCommit: 提交前自动 `just generate-claude` 同步配置
  - PostCommand: nixos-rebuild build 后提示写复盘
- **持久化记忆**: 跨会话保留上下文（路径见 CLAUDE.md）
- **Plan mode**: 修改配置前内置架构设计方案步骤

### OpenCode 对齐方式

OpenCode 无 hooks/持久化记忆等机制，通过以下方式对齐 Claude 的工作流：

| 场景 | OpenCode 做法 |
|------|-------------|
| 配置自动生成 | 改完 `lib/opencode-config.nix` 后手动执行 `just generate-opencode` |
| 复盘提醒 | plan prompt 中内置"改完写复盘"步骤 |
| 跨会话上下文 | 开工前读 `retros/` 了解进度 |
| Plan mode | `default_agent = "plan"` + plan prompt 内置开工检查清单 |

## 常见陷阱
- swaync/swayidle/polkit-gnome 是 HM 选项，不是 NixOS 选项
- Niri 不支持 Hyprland 式 submap，用 `switch-to-named-submap`
- `linuxPackages_lts` 在 nixpkgs 25.11 不存在 (用 `linuxPackages_6_12`)
- nvidia-offload 调用独显: `nvidia-offload <command>`
