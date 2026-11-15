# 多 Agent 协作与 Paseo 编排

> 目标: 让多个 AI (OpenCode / Claude Code / Codex / Hermes) 并行干活时不再抢同一个工作区喵~
> 入口: Paseo daemon 127.0.0.1:6767 (浏览器开 http://localhost:6767), CLI 为 `paseo` 喵~
> 本机**没装 Electron 桌面端** (用户 2026-11-15 选择不要 GUI), 用 web UI + CLI 喵~

## 为什么需要这一层

以前的打架方式是: 多个 session 在同一个 checkout 里改文件喵,未提交改动互相污染喵,
`git status` 分不清谁改的喵,验证命令跑的是混合状态喵,最后只能靠人肉 stash 和猜喵~
Paseo 的解法不是"合并编辑"喵,而是**把并行工作物理隔离到各自的 git worktree**喵~

## 三条不变量 (违反就等于回到打架状态)

1. **一个任务 = 一个 worktree = 一个分支 = 一个 owner agent** 喵~
2. **同一个分支同一时刻只允许一个 agent 写** 喵,其他 agent 只能读或提意见喵~
3. **合并只有一个执行者** 喵: 交互 session (OpenCode) 或用户本人喵,
   并行 worker 只负责交 diff 和验证输出喵~

## 分层

| 层 | 组件 | 职责 |
|----|------|------|
| 编排 | Paseo daemon (+ web UI) | 会话容器、worktree 创建、并行调度、diff 审阅 |
| 隔离 | git worktree (Paseo workspace) | 每个任务独立 checkout + 独立分支 |
| 知识 | `.agents/` + kb-mcp (`kb_search`) | 约定、复盘、已知问题、语义检索 |
| 验收 | `VALIDATE_CMD` + 复盘 | 合并前的可信闸门 |

## 分工

| Agent | 定位 | 用法 |
|-------|------|------|
| OpenCode | 交互主力 / **合并 owner** | 主 checkout 里跑,负责最终合入与验收 |
| Claude Code | 深度实现、重构 | Paseo provider,跑在 worktree |
| Codex | 第二意见 review | Paseo provider,只读 review,不改文件 |
| Hermes Agent | 常驻长任务 (cron / 消息网关) | `hermes` CLI + gateway 常驻,不抢前台仓库 |
| Paseo | 编排与并行 | web UI / `paseo run` 新建 workspace,Isolation = New worktree |

## Paseo 使用约定

- 一个 issue / 一个需求 = 一个 workspace 喵,起点用 `origin/main` 喵~
- worker 只在**自己 worktree 的 cwd** 内改文件喵,禁止 `cd` 到主 checkout 改同一份代码喵~
- 跨 agent 沟通两条路: `paseo send <agent-id>` 实时对话喵,或 `.agents/dialogue/` 写交接文件喵~
  (长任务、需要留痕的用文件喵,临时问答用 send 喵)
- 分支命名沿用 `feat/<slug>` / `fix/<slug>` 喵,与 AGENTS.md 三级工作流一致喵~
- 合并前 worker 必须跑 `VALIDATE_CMD` 并把结果贴回 diff 说明喵,
  没跑验证的 workspace 一律不合并喵~

## 知识层边界 (重要)

- worktree 里的 `.agents/` 是**分支副本**喵,kb 索引只覆盖主 checkout
  (`/etc/nixos/.agents`、`~/WorkSpace/<proj>/.agents`)喵~
- 因此**复盘和知识更新只在主 checkout 或专门 docs 分支写**喵,worktree 内视为只读喵~
  否则分支一删,复盘跟着消失喵~
- 在 worktree 里 `kb_search` 可能回落到系统库喵,查项目经验请回主 checkout 查喵~

## 已知限制

- **gh 的 keyring token 拿不到**喵: Paseo 是 systemd system service,没有 gnome-keyring 会话喵~
  `git push` (ssh key) 正常喵,`gh pr create` 之类需要 PR 自动化时再补 agenix `GH_TOKEN` 喵~
- Paseo **不解决合并冲突** 喵,它只把冲突从"同时改"推迟到"合并时"喵~
- 状态目录统一在 `PASEO_HOME=/home/reiky/.paseo` 喵~ 若以后装 Electron 桌面端,
  让它连 `http://127.0.0.1:6767` 而不是自己再拉一个 daemon 喵~

## 端口 / 服务对照

| 端口 | 服务 | 备注 |
|------|------|------|
| 6767 | paseo daemon | 仅 127.0.0.1,relay 关闭 |
| 3080 | dsh-fence | 见铁律: switch 前确认无手动进程 |
| 8642 | Hermes Desktop backend (未装 GUI, 保留) | CLI 与 gateway 共用 `~/.hermes` |
