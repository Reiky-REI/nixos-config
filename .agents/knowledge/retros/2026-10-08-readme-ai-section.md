---
date: 2026-10-08
module: README.md, .agents/artifacts/delete-manifests/, .agents/knowledge/INDEX.md
tags: [readme, docs, ai-collab, wake-agent, guardrails, agent-resume, kb-mcp, workspace-cleanup]
layer: docs
severity: low
related:
  - ../INDEX.md
---

# 复盘: README 新增「AI 协作体系」章节 + 工作区清理 (2026-10-08)

## 背景

README 里 AI 相关内容散落三处（§3 目录树带过、§6 一小节「AI agent 注册」、
§11 wake-agent / agent-resume），缺一个系统总览喵~ 用户要求把 AI 内容补全，覆盖
**合作机制 / 经验体系 / 运行时**，并明确点出「互相唤起 / 自动唤起」与
「护栏机制（高危操作）」两块喵~

## 变更

- README 新增第一章 **「AI 协作体系」**，原 §1~§13 顺延为 §2~§14喵
  六层结构：参与方与注册 / 协作机制 / 自动唤起与互相唤起 / 护栏机制 / 经验体系 /
  运行时与工具链喵
- 原 §7 的「AI agent 注册 (`agents.nix`)」小节瘦身为指回第 1 章的指针，避免重复喵
- 新增删除清单 `.agents/artifacts/delete-manifests/2026-10-08-splayer-settings-orphan.md`喵

## 关键事实（写 README 前逐一核实）

- **自动唤起**：`rebuild.sh` → `wake-agent.sh` 在调用者 Wayland 会话开
  `alacritty -e opencode --continue`；`switch` 默认开 / `build` 默认关；
  已有交互会话只通知 + 留消息板；`queue-task.sh --wake` 走 `WAKE_FORCE=1` 强开喵
- **护栏三层**：`opencode.json` deny 高危 shell、`.claude/settings.json` 白名单、
  高危操作脚本封装（`rebuild.sh` 警告 / `nix-prune-generations` 默认 dry-run /
  `commit.sh` 只推 feature branch）、`dsh-fence` systemd 沙箱喵
- **经验体系**：kb-mcp 走本机 llama.cpp embedding（:8081）+ reranker（:8082）喵

## 工作区清理

- 删除 `feat/waydroid-aixue` 工作区里的孤儿副本 `home/reiky/apps/splayer-settings.json`喵
  - 它与 `5c5b5f1^` 的 blob 逐字节相同（sha256 `acae855e…`），SPlayer 已卸载喵
  - 按铁律**先落删除清单再删**；内容在 git 历史仍可取回喵
  - main 不受影响（main 仍启用 SPlayer，该跟踪文件保留）喵

## 验证

- `just check-docs`：新增章节引用的仓库路径全部存在喵
- `git status`：`feat/waydroid-aixue` 仅剩既有的 waydroid mitmproxy 未提交改动（本次刻意不碰）喵

## 遗留 / 未做

- waydroid mitmproxy `extraArgs` 4 行改动未动（属 waydroid 任务）喵
- 缺失的 `retros/2026-10-07-waydroid-aixue-phase0-env.md` 未补（属 waydroid 任务）喵
- 陈旧分支 `ai/blueprint-design` / `ai/nixmeow-system`、dialogue 积压、pending 申请未处理喵
