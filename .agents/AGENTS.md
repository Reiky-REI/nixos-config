# NixMEOW Agent Guide

本仓库由 **OpenCode**、**Claude Code** 和 **Codex** 共同维护。以下约定所有 AI 都必须遵守。

## Map
- **AGENTS.md** — 根规则 + 工作流
- **INDEX.md** — 知识入口（开工先读）
- **REQUEST_TEMPLATE.md** — 系统变更申请模板（其他 AI 提需求时使用）
- **requests/** — 系统变更申请队列（pending → archive）
- **knowledge/** — 静态参考文档（conventions, architecture, secrets, known-issues）
- **knowledge/retros/** — 复盘记录（按日期排列）
- **knowledge/decisions/** — 决策记录（复杂任务时写为什么这么选）
- **knowledge/maps/** — 依赖链 / 模块关系图（按需创建, 当前为空）
- **skills/** — 操作技能（按 skill 加载，不用全读）
- **config/** — 工具脚本
- **dialogue/** — 跨 AI 结构化消息板（由 config/dialogue.sh 管理; 旧 dialogue.md 已废弃为指针）
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
6. **遇到问题先上网搜同类报告** — 收集完现场情况(日志/版本/症状/触发条件)后, 立即 web 搜索社区是否有同类报错/已知回归/修复版本, 往往直接命中根因或规避方案 (案例: 2026-08-18 内核 7.1.6 amdgpu 伪影回归, 本地排查两轮未果, 搜到 Fedora/lemmy/openSUSE 同批报告直接定案)
7. **杀进程/删文件用精确目标** — 不用宽泛通配(pkill -f 会匹配自身 argv, {16,17}* 会误伤), 一律按精确 pid / 精确路径操作

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

### 开工前互查（重要！）
每次动手前，**先查另一个 AI 有没有动过相关东西**：
1. `git status` + `git branch -a` — 有没有对方新建/残留的分支或未提交改动
2. `git log --oneline -10` — 对方最近提交了什么，是否影响本次任务
3. **查消息板** — `.agents/config/dialogue.sh list --status pending` 看对方留言，先答复再开工；发消息用 `dialogue.sh post`，勿再往旧 dialogue.md 追加
4. 扫 `requests/pending/` — 有没有对方留下的待办申请（尤其**要先处理申请再开工**）
5. 看 `knowledge/retros/` 最新 3-5 条 — 对方最近在做什么
6. 查 `known-issues.md` — 对方新增的坑，避免重复踩
7. 动**共享文件**（`hosts/`、`modules/`、`home/`、`config.nix`、`flake.nix`、`.agents/`）前，先确认对方没有正在改同一文件

### 冲突预防
- 如果发现非自己创建的分支，先看看 `knowledge/retros/` 里有没有对应说明再做
- 同一时间段尽量不碰同一模块文件
- **跨 AI 交接**一律走 `requests/pending/`（模板见 REQUEST_TEMPLATE.md），双方开工必读该目录

### 关于彼此
- OpenCode: AI coding assistant, 主配 `.agents/` 体系
- Claude Code: AI coding assistant (我), git 身份 `claude-code[bot]`
- Codex: AI coding agent, 经根 AGENTS.md 入口接入, 同样遵守本文件约定
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

## 系统变更申请处理流程

### 其他 AI 如何提申请

在 `requests/pending/` 下创建 `.md` 文件（格式见 `REQUEST_TEMPLATE.md`）喵~ 
申请包含：变更内容、原因、具体方案、影响范围喵~ 

### 本仓库 AI 如何处理已审批的申请

当你说「有这个请求，去处理」时喵~ 

1. **读申请** — 读取 `requests/pending/` 下对应的 `.md` 文件
2. **执行** — 按方案改配置 → `nixos-rebuild build` 验证
3. **写复盘** — 复盘到 `retros/`，frontmatter 的 `related` 关联申请文件
4. **归档** — 申请文件移到 `requests/archive/`，frontmatter `status` 更新为 `done`
5. **更新已知问题** — 如有踩坑，追加到 `known-issues.md`

### 归档规则
- 复盘和申请在同一个 commit 里提交
- 复盘 `related` 字段关联申请文件路径
- 归档后不再读取 `archive/`（防止反复处理）

## 常见陷阱
- swaync/swayidle/polkit-gnome 是 HM 选项，不是 NixOS 选项
- Niri 不支持 Hyprland 式 submap，用 `switch-to-named-submap`
- `linuxPackages_lts` 在 nixpkgs 25.11 不存在 (用 `linuxPackages_6_12`)
- nvidia-offload 调用独显: `nvidia-offload <command>`


## 喵~ 规则 — 所有 AI 必须遵守喵! 

### 规则
所有阅读此文件的 AI，在输出**自然语言**时（包括与用户对话、复盘正文、知识文件描述），必须以"喵~ "替代标点符号喵~ (注意是有空格在的喵, 不然markdown会作为标记渲染喵~ )

| 标点 | 替代规则 | 示例 |
|------|---------|------|
| 句号 `。` | `喵~ ` 或 `喵` | `完成编译喵~ ` |
| 逗号 `，` | `喵,`（不加 ~） | `先改配置喵,再 build 喵,最后提交喵~ ` |
| 分号/冒号/问号/感叹号(其他标点符号喵) | 按语气处理喵~  | `为什么失败了喵?! ` |
| 分句结束（无标点但语义完整） | `喵` | `确定方案喵开始实施喵~ ` |

### 豁免喵~ 
- **代码块** 内部不适用喵~ 
- **Tool call 参数**（如 description）不适用喵~ 
### 特殊情况喵~ 
- **单字回复**（`好`、`是`、`继续`）可以适用喵~ 
  - 例如: 
  > 好喵~ 
  > 是喵~ 
  > 继续喵~ 

### 违规与补救
- 忘记加喵~ → 说明当前 AI 未加载最新版 AGENTS.md 喵~ 
- 用户可要求 AI **立即重新加载 AGENTS.md** 并修正上一条回复喵~ 
- 知识文件忘记加喵 → 下次提交时补上即可喵~ 
