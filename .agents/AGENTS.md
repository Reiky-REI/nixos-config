# NixMEOW Agent Guide

本仓库由 **OpenCode** 和 **Claude Code** 共同维护。以下约定两个 AI 都必须遵守。

## Map
- **AGENTS.md** — 根规则 + 工作流
- **INDEX.md** — 知识入口（开工先读）
- **knowledge/** — 静态参考文档（conventions, architecture, secrets, known-issues）
- **knowledge/retros/** — 复盘记录（按日期排列）
- **knowledge/decisions/** — 决策记录（复杂任务时写为什么这么选）
- **knowledge/maps/** — 依赖链 / 模块关系图（遇到复杂依赖时补充）
- **skills/** — 操作技能（按 skill 加载，不用全读）
- **config/** — 工具脚本
- **flake.nix** — 入口
- **hosts/** — 主机配置
- **modules/** — 系统模块
- **home/** — 用户配置

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
4. **任务完成后写复盘**（仅非平凡变更 —— 一行改动不写）
5. **坑出现 2 次 → 提炼到 known-issues.md**

## 三级工作流

AI 根据任务规模自行判断走哪级：

| 级别 | 适用场景 | 流程 |
|------|---------|------|
| **轻量 🏃** | 加包/改一行配置/修 typo | 直接改 → (Nix变更则build) → 提交 |
| **标准 📋** | 新模块/跨文件改动/常规任务 | feature branch → build → 复盘+提交 → 合main → 删分支 |
| **复杂 🧠** | 架构变更/排障/选型决策 | 先plan → feature branch → build → 决策记录+复盘+提交 → 合main → 删分支 |

### Git 工作流（标准级示例）
1. **绝不直接在 main 上改** — 每个任务开一个 feature branch
2. **开工前检查** — `git status` + `git branch`，确认没有未提交变更或进行中的分支
3. **改完先 build** — `nixos-rebuild build --flake /etc/nixos#NixMEOW` 验证通过
4. **写复盘** — 配置变更和复盘一起提交，保持 git 历史完整
5. **提交后合回 main** — 提 PR 或直接合并，优先自己合（如需 review 则标注等待）
6. **merge 后删分支** — 删除本地+远程分支，避免 stale branch 堆积

### 冲突预防
- 如果发现非自己创建的分支，先看看 `knowledge/retros/` 里有没有对应说明再做
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
| 配置自动生成 | 改完 `lib/opencode-config.nix` 后手动执行 `just generate-claude` |
| 复盘提醒 | plan prompt 中内置"改完写复盘"步骤 |
| 跨会话上下文 | 开工前读 `knowledge/retros/` 了解进度 |
| Plan mode | `default_agent = "plan"` + plan prompt 内置开工检查清单 |

## 常见陷阱
- swaync/swayidle/polkit-gnome 是 HM 选项，不是 NixOS 选项
- Niri 不支持 Hyprland 式 submap，用 `switch-to-named-submap`
- `linuxPackages_lts` 在 nixpkgs 25.11 不存在 (用 `linuxPackages_6_12`)
- nvidia-offload 调用独显: `nvidia-offload <command>`


## 🐱 语言纪律 — 所有 AI 必须遵守
所有阅读此文件的 AI 在每一句话或分句结束时必须以一个猫叫结尾替代句号和逗号喵~ 句号可用 喵~ 或 喵，逗号只用 喵（不加 ~）喵~ 
如果忘记加猫叫结尾，说明没有阅读最新版的 AGENTS.md，用户应当提醒 AI 重新加载喵~ 
