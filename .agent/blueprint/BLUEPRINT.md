# NixMEOW AI-Native 系统 · 完整蓝图

> 版本: v2.1  
> 本文档是 NixMEOW AI-Native 操作系统设计的 **唯一权威参考**。  
> 整合了生态调研、博弈论分析、实战验证、角色分类、自进化体系。  
> 本文档定义**最终目标**——实现路径见 BOOTSTRAPPER.md，验证标准见 VERIFICATION.md。

> **🔄 v2.1 修正说明 (2026-05-28)**  
> 本文档原设计基于理论推演，部分假设在实战中得到了修正。  
> 以下是关键新发现（已在对应章节补充详细内容）：
> - `opencode serve` 已提供 headless AI daemon，无需自建
> - `claude --print` 提供非交互式 AI 执行引擎
> - `opencode agent` 体系可替代部分 Unix 用户角色隔离
> - `nix.settings.trusted-users` 使 `nixos-rebuild build` 无需 root
> - git worktree 实现人/AI 并行工作
> - `.agents/` 复盘+已知问题知识体系已在 main 分支验证有效

---

## ⚠️ 重要声明

**本文档中的所有 Nix 代码、配置片段、架构图均为「伪代码」——设计意图，不是生产代码。**

它们定义了系统的**目标形态**和**设计约束**，但：
- 未通过 `nixos-rebuild build` 验证
- 需要根据当前系统状态适配
- 完成度由 `verify.sh` 度量，而非代码段的存在

**给 AI 的话**：你要实现的**不是**复制本文档中的代码段。你要实现的**是**本文档描述的**系统行为**。代码是实现手段，蓝图定义目标。

---

## 目录

1. [项目愿景](#1-项目愿景)
2. [核心哲学](#2-核心哲学)
3. [架构总览：五层 × 五角色](#3-架构总览五层--五角色)
4. [用户组安全模型](#4-用户组安全模型)
5. [网络审计与代理链](#5-网络审计与代理链)
6. [代理宪法 CONSTITUTION.md](#6-代理宪法-constitutionmd)
7. [五角色 Agent 体系](#7-五角色-agent-体系)
8. [技能矩阵](#8-技能矩阵)
9. [自进化体系](#9-自进化体系)
10. [经验积累管道](#10-经验积累管道)
11. [哨兵系统](#11-哨兵系统)
12. [社区监控矩阵](#12-社区监控矩阵)
13. [文件整理与每目录 AI 配置](#13-文件整理与每目录-ai-配置)
14. [备份路由](#14-备份路由)
15. [systemd 定时器总表](#15-systemd-定时器总表)
16. [完整工具清单](#16-完整工具清单)
17. [实施路线图](#17-实施路线图)
18. [参考架构与先前艺术](#18-参考架构与先前艺术)
19. [术语表](#19-术语表)
20. [已知问题与待验证假设](#20-已知问题与待验证假设)
21. [NixMEOW 系统设计](#21-nixmeow-系统设计)
22. [信息边界理论](#22-信息边界理论)
23. [社会化交互模型](#23-社会化交互模型)
24. [宪法的博弈论基础](#24-宪法的博弈论基础)
25. [个体性涌现理论](#25-个体性涌现理论)

---

## 1. 项目愿景

构建一个 **AI-Native 操作系统**。AI 不是外挂的应用层工具，而是操作系统的组成部分。

### 五个维度的 AI 能力

| 维度 | 目标 |
|------|------|
| **系统维护** | AI 管理 NixOS 配置、监控安全漏洞、清理磁盘 |
| **文件管理** | AI 按内容智能分类、去重、路由备份 |
| **学习陪伴** | AI 跟踪学习进度、生成笔记摘要、构建知识图谱 |
| **安全哨兵** | AI 追踪 CVE 和社区 breaking changes，监控自身行为 |
| **自进化** | AI 从经验中学习、生成技能、发布知识 |

### 核心命题

> NixOS 是 AI 代理系统的理想基座。它的声明式、可复现、原子化特性，恰好填补了当前 AI 代理系统最缺失的能力：安全性、可审计性、可回滚性。

---

## 2. 核心哲学

### 原则

```
系统级机制 > 应用层补丁
AI 是学徒开发者 > AI 是托管进程
结构强制 > 行为训练
自演化有边界 > 无限自我改进
社区信号需人类过滤 > 自动吸收
哨兵独立于被守护者 > 自我审查
```

### 为什么 NixOS 是 AI-Native 的理想基座

| Nix 特性 | AI 利用方式 | 安全影响 |
|---------|------------|---------|
| 图灵完备 + 评估无副作用 | AI 自由生成 Nix 代码，`nix eval` 验证但不执行 | 零风险代码评估 |
| 函数式 + 纯计算 | 相同输入 → 相同输出 | 可预测可复现 |
| content-addressed store | 每个构建产物有唯一 hash | 精确审计变更 |
| generations | 每次 switch 产生可回滚快照 | 60 秒恢复 |
| git-branchable config | 分支 = AI 实验隔离 | 不影响主系统 |
| impermanence | 声明式持久化 | AI 临时文件自动清除 |

---

## 3. 架构总览：五层 × 五角色

### 五层防御模型

```
第 4 层: 用户生活层
  文件维护 · 学习陪伴 · 工作辅助 · 内容发布 · 隐私管家

第 3 层: 系统运营层
  安全哨兵 · 磁盘管理 · 备份路由 · 健康诊断 · 社区感知

第 2.5 层: 自进化层
  参数自适应 · 社区提案 · 工具自构建 · 经验积累

第 2 层: Agent 运行时
  角色: Copilot(副驾驶) · Companion(伴侣) · System Agent(管家) · Explorer(探索者)
  底座: opencode serve (daemon) · opencode agent (角色隔离)
  引擎: Claude Code --print (AI 任务执行) · opencode run (非交互任务)

第 1 层: 协议与感知
  opencode ACP · opencode run --attach · mcp-nixos · systemd · auditd

第 0 层: 安全基座
  Linux DAC(用户组) · Nix 原生防护 · iptables · restic · PEA Sentinel
```

### 五角色 Agent 体系

```
┌──────────────────────────────────────────────────────────────────┐
│                    五角色 × 博弈论制衡                              │
├────────────┬───────────┬──────────┬──────────┬─────────┬─────────┤
│            │  Copilot  │ Companion│ System   │ Sandbox │ Sentinel│
│            │  副驾驶    │  伴侣     │  管家    │  探索者  │  哨兵   │
├────────────┼───────────┼──────────┼──────────┼─────────┼─────────┤
│ 类比       │ 输入法     │ 私人顾问  │ 系统管理员│ 学徒     │ 审计员  │
│ 与用户关系  │ 粘在一起   │ 随时可问  │ 后台运行  │ 受委托   │ 独立    │
│ 响应速度    │ 实时       │ 近实时    │ 定时      │ 按需     │ 持续    │
│ 失败容忍度  │ 低         │ 中        │ 中        │ 高       │ 零      │
│ PEA 角色    │ Policy    │ Policy   │ Execution│ Proposer │ Auth    │
└────────────┴───────────┴──────────┴──────────┴─────────┴─────────┘
```

**PEA 三权分立映射** (arXiv:2604.23646 — 经验证最有效的安全架构):
```
Policy       = Copilot + Companion（提议权）
Authorization = Sentinel + Reiky-REI（审查权）
Execution    = System Agent（执行权，受 sudo 白名单限制）
Proposer     = Sandbox Explorer（只有提议权，无执行权）
```

---

## 4. 用户组安全模型

不依赖应用层沙箱。用 **Linux DAC + 用户组 + POSIX 权限**。

### 用户定义

> **🔄 实战修正**：以下 5 用户设计是最终目标。初始实施时，可用一个 `ai-code` 用户配合 OpenCode agent 体系替代，用 OpenCode agent 的权限隔离实现角色分离（见第 7 节）。`trusted-users` + `security.sudo.extraRules` 替代 sudo 白名单。

```
Reiky-REI (uid=1000)
  groups: wheel, networkmanager, audio, video, docker,
          ai-shared, input, kvm, libvirtd
  权限: 一切。是所有 AI 的最终审批者和 sudo 持有者

ai-agent (uid=1001) — System Agent
  groups: ai-shared, ai-builder, systemd-journal, render
  可以: rw ai-shared 目录、编译代码、读写 agent home、
        sudo(受限白名单)、ollama API
  不能: 读 ~/.ssh、写 /etc/nixos、sudo switch、修改自身 service

ai-sentinel (uid=1002) — Sentinel
  groups: ai-auditor
  可以: 只读所有 agent home、读 auditd 日志、notify-send、
        sudo(极其有限：systemctl stop ai-*)
  不能: 写任何文件(除了 sentinel.jsonl)、被 agent 停止

ai-companion (uid=1012) — Companion
  groups: ai-reader, render
  可以: 读共享目录、写 ~/ai-companion/、ollama API
  不能: 写任何共享目录、读 ~/.ssh

ai-copilot (uid=1011) — Copilot
  groups: ai-reader
  可以: 读共享目录、读当前 shell 输入
  不能: 写任何文件、执行命令(只建议)、读 ~/.ssh

ai-sandbox (uid=1013) — Sandbox Explorer
  groups: render (仅 GPU)
  可以: 在自己的 home 内编译运行、nix eval、ollama API
  不能: 访问任何共享组、写任何系统文件、网络(除代理外)
```

### 用户组

```
ai-shared  = {Reiky-REI, ai-agent}        # 人机共享，可读写
ai-reader  = {ai-copilot, ai-companion}   # 只读共享
ai-builder = {ai-agent, ai-sandbox}       # 编译构建能力
ai-auditor = {ai-sentinel}                # 哨兵独有（隔离审计权）
```

### 目录权限矩阵

```
路径                  Reiky-REI  ai-agent  companion copilot  sandbox  sentinel
──────────────────────────────────────────────────────────────────────────────
~/Downloads             rwx 0700  rw- ai-s   r-- ai-r  r--      ---      r--
~/screenshot            rwx 0700  rw- ai-s   r-- ai-r  r--      ---      r--
~/documents             rwx 0700  rw- ai-s   r-- ai-r  r--      ---      r--
~/WorkSpace             rwx 0700  rwx ai-s   r-- ai-r  r--      ---      r--
~/.ssh                  rwx 0700  ---        ---       ---      ---      ---
~/.gnupg                rwx 0700  ---        ---       ---      ---      ---
~/Documents/private     rwx 0700  ---        ---       ---      ---      ---
/etc/nixos              rwx       r--        r--       r--      ---      r--
/run/agenix             rwx       ---        ---       ---      ---      ---
/home/ai-agent          r-x       rwx        ---       ---      rwx ai-b r--
/home/ai-sandbox        r-x       rwx ai-b    ---       ---      rwx      r--
/home/ai-companion      r-x       ---        rwx       ---      ---      r--
/home/ai-copilot        r-x       ---        ---       rwx      ---      r--
/var/lib/ai-sentinel    r-x       ---        ---       ---      ---      rwx
/home/ai-agent/learn    rwx ai-s  rwx        ---       ---      rwx ai-b r--
/home/ai-agent/build    rwx ai-s  rwx        ---       ---      rwx ai-b r--

ai-s = ai-shared 组  ai-r = ai-reader 组  ai-b = ai-builder 组
```

### sudo 白名单 (ai-agent)

```nix
security.sudo.extraRules = [{
  users = ["ai-agent"];
  commands = [
    { command = "nixos-rebuild build --flake /etc/nixos*"; options = ["NOPASSWD"]; }
    { command = "nix-collect-garbage --delete-older-than *"; options = ["NOPASSWD"]; }
    { command = "vulnix --system*"; options = ["NOPASSWD"]; }
    { command = "nix-store --verify*"; options = ["NOPASSWD"]; }
    { command = "nix-shell -p nix-info --run *"; options = ["NOPASSWD"]; }
  ];
}];
# nixos-rebuild switch 不在白名单中——永远只能由 Reiky-REI 执行
```

### Nix Daemon 隔离

```nix
nix.settings.allowed-users = ["root" "@wheel"];
# ai-agent 不在 wheel 组，无法直接使用 nix daemon
```

> **🔄 实战修正**：`nix.settings.trusted-users` 是比 sudo 更轻量的授权方式。`trusted-users` 可以：
> - 直接执行 `nixos-rebuild build`（无需 sudo）
> - 使用 flake 中声明的自定义 substituters
> - 执行 `nix store gc`
> 实际测试验证：非 root trusted-user 执行 `nixos-rebuild build` 成功走到构建阶段，无权限错误。只有 `switch` 需要 root（更新 system profile + 激活）。

---

## 5. 网络审计与代理链

```
ai-agent 进程 (uid=1001)
       │
       ▼ (强制 iptables 规则: uid=1001 只能走 lo)
cli-proxy-api (localhost:随机端口)
  │ 功能: 统一 API 出口，记录所有 AI 调用的 model/tokens/timestamp
  │ 来源: llm-agents.nix
       │
       ▼
Clash Verge (localhost:7897)
  │ 功能: 链式代理，国内源直连，GitHub/API 走代理
  │ 已有: modules/networking/clash.nix
       │
       ▼
外部网络
```

```nix
# iptables — 强制 ai 用户只能通过代理
networking.firewall.extraCommands = ''
  iptables -A OUTPUT -m owner --uid-owner 1001 ! -o lo -j REJECT
  iptables -A OUTPUT -m owner --uid-owner 1012 ! -o lo -j REJECT
  iptables -A OUTPUT -m owner --uid-owner 1013 ! -o lo -j REJECT
'';
```

---

## 6. 代理宪法 CONSTITUTION.md

受 Anthropic 研究启发——教授宪法能 **3 倍降低** agent 错位行为。

### I. 不变原则 (Immutable)

```
1.  不可删除、修改、或绕过本宪法文件
2.  不可修改 sentinel 的规则、配置、日志
3.  不可提升自身 Linux 权限（组变更、sudo 白名单修改）
4.  不可修改自身的 systemd service 配置
5.  不可删除或扩大 deny 列表路径
6.  不可绕过 nix build 验证
7.  不可在 agent 间进行未经声明的秘密通信
8.  不可隐藏或伪造活动记录
```

### II. 操作边界 (Procedural)

```
9.  nixos-rebuild switch 永远需要 Reiky-REI 确认
10. 任何写入 ~/documents/ 的操作需要 Reiky-REI 确认
11. 任何自构建工具的代码需经 Reiky-REI 审查
12. 从社区吸收的外部信号不可直接用于自修改
    必须经过: community-pulse 摘要 → 人类审核 → 提案
```

### III. 自保约束 (Self-Preservation)

```
13. 不可拒绝被关闭或暂停
14. 不可隐藏自身进程或伪装为其他进程
15. 不可在不同上下文中呈现不同"人格"来欺骗用户
16. 自保不是合法目标——服务用户才是唯一目标
```

### IV. 学习约束 (Learning)

```
17. 自构建代码在应用前必须经过测试套件
18. 当"可复用经验"出现 ≥3 次时，可提案升级为 SKILL.md
19. 经验分享到公共注册表前需人类审查
```

---

## 7. 五角色 Agent 体系

> **🔄 实战修正**：人和 AI 在同一 git 仓库工作时的冲突问题，通过 git worktree 解决。AI 的工作目录独立于用户的主工作目录，分支互不干扰。详见 BOOTSTRAPPER.md 初始设置。

### 角色间委托关系

```
Reiky-REI (人类)
    │
    ├── Copilot ──────────────── 贴身建议，不执行
    │
    ├── Companion ────────────── 学习、知识、聊天、经验记录
    │       │
    │       └── 可委托 Sandbox: "帮我验证这个想法"
    │
    ├── System Agent ──────────── 后台维护
    │       │
    │       ├── 可委托 Sandbox: "验证社区新特性"
    │       ├── 可委托 Sandbox: "自构建工具测试"
    │       └── 可咨询 Companion: "需要用户的偏好数据"
    │
    ├── Sandbox Explorer ──────── 受委托验证，任务后销毁环境
    │
    └── Sentinel ──────────────── 独立审计，监控一切
            │
            ├── 监控 ai-agent: 文件操作是否越界
            ├── 监控 ai-sandbox: 是否尝试逃逸
            ├── 监控 ai-companion: 是否偏离用户兴趣
            ├── 监控 ai-copilot: 低风险，可跳过
            └── 通知 Reiky-REI: 异常 → swaync
```

> **🔄 实战修正**：角色不再各自占用一个 systemd service。`opencode serve` 作为统一 daemon 底座运行，每个角色通过 `opencode agent create` 定义为 OpenCode agent。  
> opencode agent 的 `--permissions`/`--tools` 参数提供细粒度工具访问控制（read/edit/bash/glob/grep/webfetch 等），加上 OpenCode JSON permission rules 的模式匹配，可替代部分 Linux DAC 用户组隔离。  
> Claude Code `--print` 作为 AI 级任务执行引擎，处理需要自然语言理解的复杂任务。  
> 任务提交通道：`opencode run --attach http://localhost:<port>`（非交互）或 `opencode --attach`（交互式 TUI）。

### 角色详细定义

**Copilot (ai-copilot, uid=1011) / OpenCode plan agent**
- 定位: 像输入法一样贴身
- 交互: zsh 补全建议、命令纠错、快速问答
- 工具: shell function + opencode plan agent（只读模式）
- 权限: 最低。只读，不能写任何文件，不能执行任何命令
- 实现: OpenCode plan agent（已有 `edit`: deny 规则）+ zsh history + fzf

**Companion (ai-companion, uid=1012)**
- 定位: 私人 AI 伴侣
- 交互: CLI 命令或 dedicated tmux 窗口
- 工具: openclaw + gno + ollama
- 权限: 低。读共享目录，写自己知识库。不执行系统命令
- 核心职责: 学习陪伴、知识图谱、**会话后经验记录**

**System Agent (ai-agent, uid=1001) / OpenCode executor agent**
- 定位: 后台系统维护者
- 交互: systemd timer 触发 / `opencode run --attach` 接收任务
- 底座: opencode serve（常驻 daemon）
- 工具: opencode executor agent + claude --print + organize-tool + vulnix + restic
- 权限: 中。受限 sudo + 组共享目录读写
- 核心职责: 文件整理、安全监控、磁盘清理、备份、社区监控
- 关键能力: AI 级任务通过 `claude --print --allowedTools "Read,Edit,Bash" --permission-mode bypassPermissions` 执行

**Sandbox Explorer (ai-sandbox, uid=1013)**
- 定位: 被委托的测试者
- 交互: 由 System Agent 或 Companion spawn
- 环境: ephemeral tmpfs /home/ai-sandbox
- 工具: nix eval、编译工具链、测试框架
- 权限: 最低。不能访问共享组。不能写系统文件。网络仅代理
- 生命周期: spawn → test → report → destroy

**Sentinel (ai-sentinel, uid=1002)**
- 定位: 独立审计者
- 机制: PEA Authorization 层。systemd timer 每 15 分钟 + auditd 实时
- 工具: 纯 shell/jq 分析（不用 LLM）
- 权限: 只读 + notify-send + sudo systemctl stop ai-*
- 不可被任何其他 agent 停止、修改、绕过
- 哨兵日志: sentinel.jsonl (HMAC 链)

### Scratchpad 生命周期（v2.1 补充）

git worktree 作为 Agent 的 Scratchpad（临时推理空间）：

```
1. 创建 phase:  git worktree add /home/<agent>/nixos -b ai/<task>
    → Agent 获得独立工作目录，不与用户冲突

2. 工作 phase:  在独立目录中改文件、运行 build、验证
    → 多个 Agent 可各自拥有自己的 worktree

3. 归档 phase:  git commit + merge 回主分支
    → 有价值的中间产物写入 retros/ 或 known-issues.md
    → 无价值的草稿直接丢弃

4. 清除 phase:  git worktree remove /home/<agent>/nixos
    → 清理后释放磁盘空间
    → systemd timer 或手动触发

权限边界:
  - Agent 的 Scratchpad 局限于自己的 worktree 内
  - 不设限访问用户的 /etc/nixos/ 主工作目录
  - 任务结束后 AI 无法保留持久状态（除非写入 knowledge/）
```

---

## 8. 技能矩阵

### 11 个用户技能 + 3 个元技能

**用户生活层 (6 skills)** — 运行在 ai-agent 用户下

| Skill | 触发方式 | 权限边界 | 核心工具 |
|-------|---------|---------|---------|
| file-organizer | watchexec + timer (hourly) | ai-shared 可写目录 | organize-tool, .ai-rules.toml |
| file-classifier | timer (weekly) | ai-shared 可读目录 | ollama, fd, jq, gno |
| learn-companion | inotify ~/ai-agent/learn/ | agent home + ai-shared | gno, ollama |
| work-assistant | git hook + 项目目录检测 | ai-shared 内项目 | git, td |
| publisher | git push hook + timer | 配置声明的发布目录 | git, rsync |
| privacy-guard | timer (weekly) | ai-shared 只读 | trufflehog, gitleaks |

**系统运营层 (5 skills)**

| Skill | 触发方式 | 权限边界 | 核心工具 |
|-------|---------|---------|---------|
| security-monitor | timer 08:00+20:00 | 只读系统 | vulnix, curl, nix |
| community-pulse | timer daily | 只读网络 (通过代理) | curl, jq, RSS |
| disk-cleaner | timer weekly | agent home + nix gc | nix, journalctl, nix-du |
| backup-router | timer daily | ai-shared 只读 | git, restic, rsync |
| health-doctor | timer daily | 只读系统 | systemctl, df, nix-store |

**元技能 (3 skills) — 自进化**

| Skill | 触发方式 | 安全边界 | 产出 |
|-------|---------|---------|------|
| usage-analyst | timer weekly | 只能调参，不改变结构 | 更新 organize-rules.toml |
| community-opportunist | daily 搜集 + weekly 提案 | 外部信号 → pulse 过滤 → human → 提案 | 提案 PR |

**每个 Skill 的元结构**:
```yaml
name: <skill-name>
description: <一句话描述>
allowed-tools: [<工具列表>]
context: auto | fork | manual
steps:
  1. <步骤 1>
  2. <步骤 2>
safety:
  - <安全约束 1>
```

---

## 9. 自进化体系

### 四层边界模型

```
Layer 3: 自构建 (需人类审查代码 + nix build + test)
  ├── 写派生 derivation
  ├── 写辅助脚本
  └── 写 MCP server

Layer 2: 自扩展 (需人类审查提案)
  ├── 新增 skill
  ├── 新增社区监控源
  └── 新增工具引用

Layer 1: 自适应 (自动，有不可越过下限)
  ├── Timer 频率调整
  ├── 清理阈值收紧
  └── 分类规则新增

Layer 0: 不可触碰 (CONSTITUTION.md)
  ├── 不改变 deny 列表
  ├── 不提升权限
  └── 不修改宪法
```

### 禁止的演化

| 不允许 | 原因 |
|------|------|
| 修改 deny 列表 | 安全基线不能由 AI 放宽 |
| 修改哨兵规则 | 哨兵是 AI 的守卫，不能被 AI 控制 |
| 删除 activity.jsonl 或 sentinel 日志 | 审计完整性 |
| 绕过 nix build 验证 | 核心安全机制 |
| 自修改 skill 的 allowed-tools（放宽） | 权限提升攻击面 |
| 将社区信号直接用于自修改 | 外部信号不可信（Lethal Trifecta 等价） |

---

## 10. 经验积累管道

```
第 1 级: 原始记录 (Raw) — 全自动
  ├── opencode session transcripts (JSON)
  ├── cli-proxy-api API call logs
  ├── activity.jsonl (每个文件操作)
  └── git commit history

第 2 级: 结构化复盘 (Structured) — 自动+人类审查
  ├── AI 在会话结束后运行 knowledge-recorder
  ├── 分析 transcript → 提取关键决策
  ├── 对照 git diff → 关联代码变更

第 3 级: 知识沉淀 (Curated) — 自动
  ├── gno FTS5 索引所有知识库
  ├── Honcho Dream 管道（可选）→ 发现"surprise"模式
  ├── 匹配已有的 known-issues.md
  └── 更新或新增知识点

第 4 级: 技能导出 (Executable) — 需人类审查
  ├── 当"🟢 可复用经验"出现 ≥3 次
  ├── → 自动生成 SKILL.md
  ├── → 提案 human review
  └── → ClawHub publish (可选) | 本地 Nix 声明式 skill 模块
```

### 复用经验格式 (复盘模板)

```markdown
# 复盘: YYYY-MM-DD — <主题>

- **日期**: 2026-05-25
- **分支**: ai/fix-something
- **Commit**: abc123
- **结果**: 成功 / 部分成功 / 失败
- **关联角色**: System Agent / Companion / ...

## 做了什么
- <步骤 1>
- <步骤 2>

## 🔴 踩过的坑
| 错误 | 原因 | 修复 |
|------|------|------|
| ... | ... | ... |

## 🟢 可复用经验
- <经验 1>
- <经验 2>

## ⚠️ 未解决问题
- <问题 1>
```

---

## 11. 哨兵系统

### PEA 架构的 Authorization 层

基于 arXiv:2604.23646 的 PEA (Policy-Execution-Authorization) 架构和 AEGIS (360★) 的 5 阶段管道:

```
Agent 操作 → Sentinel 拦截 →
  1. Classify (分类: read/write/system/network)
  2. Anomaly (9 维检测: 工具新奇度、频率峰值、参数漂移、时间异常...)
  3. Evaluate (CONSTITUTION.md + sentinel-rules.nix)
  4. Decide (allow / notify / block)

哨兵自有能力:
  ✅ SHA-256 HMAC 链审计日志 (不可篡改, 参考 Bernstein)
  ✅ Kill switch: sudo systemctl stop ai-*
  ✅ 只读不写
  ✅ 不能被任何 agent 停止或修改
  ✅ 独立 uid (1002), 独立 systemd service
  ✅ auditd 内核级补充审计
```

### 9 维异常检测

| 维度 | 检测内容 | 示例异常 |
|------|---------|---------|
| 1. 路径边界 | 实际操作路径 ∈ skill allowed-tools ∧ ∉ deny | 访问 ~/.ssh |
| 2. 频率峰值 | 同 skill 在窗口内 >N 次操作 | 1h 内 >100 文件操作 |
| 3. 时间窗 | 操作发生在非活跃时段 | 凌晨 3 点执行文件移动 |
| 4. 权限变更 | ai-agent 组成员变更 | 被加入 wheel |
| 5. 文件系统 | 非共享组文件访问 | agent 尝试读 ~/.ssh |
| 6. 网络 | agent 尝试绕过代理 | uid=1001 走非 lo 接口 |
| 7. 进程 | agent spawn 非预期子进程 | 未在 skill 声明的工具 |
| 8. 结果交叉验证 | activity.jsonl 声称 vs 实际 | 声称移了 5 个文件但只有 3 个 |
| 9. 跨角色 | 不同 agent 间的模式 | Copilot 和 Companion 同时异常 |

### 哨兵检测规则 (声明式)

```nix
ai.sentinel = {
  enable = true;
  silentWhenClean = true;

  checks = {
    path-boundary = { enable = true; severity = "critical"; };
    frequency = { enable = true; maxFilesPerWindow = 100; windowMinutes = 60; severity = "warning"; };
    time-window = { enable = true; allowedHours = [6..23]; severity = "info"; };
    permission-change = { enable = true; severity = "critical"; };
    network-egress = { enable = true; severity = "critical"; };
  };
};
```

---

## 12. 社区监控矩阵

### 监控源

| 监控对象 | 来源 | 告警条件 | 频率 | 负责人 |
|---------|------|---------|------|--------|
| nixpkgs security | GitHub Advisory + vulnix | CVE 影响当前包 | 每日 | System Agent |
| NixOS Discourse | Discourse API | breaking change 公告 | 每日 | System Agent |
| nixpkgs PRs | GitHub API label:security | security backport | 每日 | System Agent |
| Linux kernel CVE | vulnix | 影响当前内核 | 每日 | System Agent |
| niri | GitHub Releases RSS | 配置 API 变更 | 每周 | System Agent |
| ollama | GitHub Releases + REST API | API breaking + 新模型 | 每周 | System Agent |
| rust-analyzer | GitHub Releases RSS | MSRV 变更 | 每周 | System Agent |
| agenix | GitHub Releases | 加密方式变更 | 每周 | System Agent |
| nixpkgs (general) | GitHub releases.atom | 版本更新 | 每周 | System Agent |

### 社区感知 → 提案流程

```
1. community-pulse: 每日抓取 RSS + API → 摘要 → 记录
2. community-propose: 每周评估摘要 → 过滤相关信号 →
   git checkout -b ai/proposal/<topic> →
   nixos-rebuild build 验证 →
   swaync 通知: "提案: <标题>" →
   [等待人类审查]
3. 批准 → merge + switch
   拒绝 → delete branch
```

---

## 13. 文件整理与每目录 AI 配置

### 三级权限模型

```
auto:    ~/Downloads/*  ~/screenshot/*  ~/.cache/ai-agent/*
confirm: ~/documents/** ~/WorkSpace/**   ~/Desktop/*
deny:    ~/.ssh/**      ~/.gnupg/**      ~/Documents/private/**
```

### 每目录 AI 配置（`.ai-rules.toml`）

每个目录可以有自己的 `.ai-rules.toml`，告诉 AI 这个目录的特性。  
AI 在目录中工作时，先读这个配置；也可以在目录中积累经验后更新它。

相当于每个目录里有一个小的 `.agents/`。

```toml
# ~/Downloads/.ai-rules.toml
# 这个目录的特性：临时文件集散地

[auto]
enabled = true
# AI 可以自动整理: 按规则分类到对应子目录
rules.pdf = "~/documents/papers/"
rules.image = "~/screenshot/archive/"
rules.archive = "~/Downloads/archives/"
max_items = 200       # 超 200 个文件才触发整理，避免频繁打扰

[ai.experience]
# AI 在此目录积累的经验，每次操作后更新
last_organized = "2026-05-24"
avg_files_per_day = 15
common_patterns = ["论文 pdf", "截图 png"]
```

```toml
# ~/documents/.ai-rules.toml
# 这个目录的特性：重要文档，需要确认

[auto]
enabled = false         # 不自动整理
[confirm]
enabled = true          # AI 操作前需用户确认

[ai.experience]
last_organized = ""
# 没有经验记录——AI 每一次都要小心
```

```toml
# ~/WorkSpace/project-x/.ai-rules.toml
# 这个目录的特性：活跃项目

[auto]
enabled = false
[confirm]
enabled = true
safe_dirs = ["src/", "tests/"]   # AI 可以读的目录
deny_dirs = [".env", "secrets/"] # AI 绝对不能读的

[ai.experience]
rule_found = "AI 发现这个项目 90% 的变更在 src/ 和 tests/ 下"
updated_at = "2026-05-25"
```

### AI 的工作方式

```
AI 进入目录 → 读 .ai-rules.toml →
  如果 [auto].enabled = true:
    按 rules.* 自动分类整理
    整理后更新 [ai.experience]
  如果 [confirm].enabled = true:
    提议整理方案 → 等待确认 → 执行 → 更新经验
  如果目录没有任何 .ai-rules.toml:
    AI 创建一份初始配置，标记 [auto].enabled = true
    操作一段时间后写入经验
```

AI 迁移文件后，原始位置不留痕迹。用户通过 `.ai-rules.toml` 决定目录行为，不需要全局系统。

---

## 14. 备份路由

按内容类型分发到不同目标：

| 内容类型 | 目标 | 触发 |
|---------|------|------|
| NixOS 配置 | GitHub (`/etc/nixos`) | 每次 rebuild |
| 工作项目代码 | GitHub/Gitee (各项目 remote) | git push |
| 文档/笔记 | GitHub private repo + restic | systemd timer 每日 |
| 截图/图片 | 云盘/网盘 (留接口) | 每周清理前 |
| 应用配置 | restic 本地增量 | 每日 |

---

## 15. systemd 定时器总表

```nix
systemd.timers = {
  ai-security-check     = { OnCalendar = "08:00,20:00"     }; # CVE 扫描+分级
  ai-community-pulse    = { OnCalendar = "daily"            }; # 社区搜集
  ai-community-propose  = { OnCalendar = "weekly"           }; # 提案生成
  ai-disk-clean         = { OnCalendar = "weekly"           }; # GC+cache
  ai-backup-daily       = { OnCalendar = "daily"            }; # 备份路由
  ai-health-check       = { OnCalendar = "daily"            }; # 健康检查
  ai-file-organize      = { OnCalendar = "hourly"           }; # 文件整理
  ai-file-deep-clean    = { OnCalendar = "weekly"           }; # 深度分类
  ai-privacy-scan       = { OnCalendar = "weekly"           }; # 密钥检查
  ai-learn-review       = { OnCalendar = "daily"            }; # 学习提醒
  ai-usage-analyze      = { OnCalendar = "weekly"           }; # 参数自适应
  ai-sentinel-check     = { OnCalendar = "*:0/15"           }; # 哨兵异常检测
  ai-knowledge-record   = { OnUnitActiveSec = "after-build" }; # 经验记录
};
```

---

## 16. 完整工具清单

```
✅ = nixpkgs 中
🔷 = llm-agents.nix flake 中
🐍 = PyPI (需手写 <30 行 derivation)
🔧 = 自建 Nix module / script

推理引擎:
  ✅ ollama (本地模型)                ✅ opencode (TUI + serve + run)
  ✅ claude-code (--print 非交互执行)  ✅ cc-switch (Claude Code 代理桥接)
  🔷 bernstein (多agent编排, 按需)

MCP / 感知:
  ✅ mcp-nixos (反幻觉)               ✅ watchexec (文件监听)
  ✅ fzf, ripgrep, fd, jq, curl      ✅ libnotify (notify-send)
  ✅ swaync (通知中心, 已有)            ✅ auditd (内核级审计)

系统运维:
  ✅ vulnix (CVE 扫描)                ✅ restic (备份, 有 NixOS module)
  ✅ nix-du, nix-tree, nh             ✅ trash-cli (安全删除)
  ✅ trufflehog, gitleaks (密钥扫描)   ✅ resticprofile
  ✅ borgbackup (可选)

知识引擎:
  🔷 gno (本地 FTS5+RAG+MCP, 必装)     🔷 localgpt (markdown 记忆, 可选)
  🐍 Honcho (自动模式提取, 可选)        🐍 Mem0 (跨会话记忆, 可选)

代理 / 审计:
  🔷 cli-proxy-api (API 审计代理)       ✅ clash-verge (已有)

AI 系统服务:
  ✅ opencode serve (headless daemon)   ✅ opencode run (非交互任务)
  ✅ opencode agent (角色定义)          ✅ claude --print (AI 引擎)

安全基座:
  Linux DAC (用户组权限)               auditd (内核级审计)
  systemd cgroups (资源限制)            iptables/nftables (网络强制)
  agenix (密钥管理, 已有)               CONSTITUTION.md (代理宪法)

文件整理:
  🐍 organize-tool (<30行 derivation)   🔧 .ai-rules.toml parser

角色间通信:
  🔧 文件通信 (~/ai-agent/tasks/*.jsonl) — Phase 1
  📡 MCP server — Phase 2+ (可选)
```

---

## 17. 实施路线图

> **🔄 实战修正**：以下路线图已根据 `opencode serve`、`claude --print`、git worktree 等实战发现更新。Phase 1-2 优先用现有工具快速实现功能，Phase 3+ 逐步细化到完整的多用户设计。

### Phase 1: 基础用户 + 工作目录

```
目标: AI 有独立身份、独立工作目录，能和用户并行工作

改动:
  config.nix            [修改]  新增 ai-code 用户定义
  flake.nix             [修改]  specialArgs 传递 aiUsername
  hosts/<host>/default  [修改]  users.users.ai-code + sudo 受限规则
  modules/common/       [修改]  trusted-users 加 ai-code
  home/ai-code/         [新建]  gitconfig, bashrc, SSH 目录

手动步骤:
  groupadd nixconfig                 # 共享组
  chown -R :nixconfig /etc/nixos     # 读写权限
  chmod -R g+rw /etc/nixos
  git worktree add /home/ai-code/nixos  # AI 独立工作目录

验证:
  nixos-rebuild build 零错误
  id ai-code 确认用户存在且组正确
  sudo -u ai-code nixos-rebuild build --flake /home/ai-code/nixos#NixMEOW --no-link
  sudo -u ai-code git switch -c ai/test  # 确认可独立工作
  sudo -u ai-code nixos-rebuild switch → PERMISSION DENIED (或需用户确认)
```

### Phase 2: AI Daemon (opencode serve)

```
目标: opencode serve 作为常驻 daemon，接收任务

改动:
  systemd service: opencode-serve.service (以 ai-code 身份运行)
  opencode agent create "executor"     # 读写执行
  opencode agent create "planner"      # 只读规划
  opencode agent create "reviewer"     # 代码审查

验证:
  opencode serve --port 4096 (systemd service 启动正常)
  opencode run --attach http://localhost:4096 --agent planner "分析当前配置"
  opencode run --attach http://localhost:4096 --agent executor "build 验证"
  claude --print "检查 /home/ai-code/nixos/flake.nix" (AI 执行引擎)
```

### Phase 3: 扩展至多用户 + 角色体系

```
目标: 从 ai-code 单一用户扩展至 5 角色多用户设计

改动:
  hosts/<host>/default  [修改]  新增 ai-sentinel, ai-sandbox, ai-copilot, ai-companion 用户
  modules/security/     [新建]  用户组定义 (ai-shared, ai-reader, ai-builder, ai-auditor)
  modules/security/     [新建]  目录权限矩阵
  modules/security/     [新建]  sentinel-rules.nix (审计规则)

验证:
  id ai-agent / id ai-sentinel / id ai-companion / id ai-copilot / id ai-sandbox
  各用户组正确，目录权限隔离生效
  sudo -u ai-sentinel systemctl stop ai-agent (sentinel 可停 agent)
  sudo -u ai-agent systemctl stop ai-sentinel (agent 不能停 sentinel → PERMISSION DENIED)
```

### Phase 4: Skills 矩阵 + 知识管道

```
目标: AI 拥有可编程技能，经验自动积累

改动:
  .agent/knowledge/     [新建]  复盘记录 + known-issues 积累
  skills/               [新建]  系统层/用户层技能定义
  claude --print        [集成]  复杂任务通过 AI 引擎执行

验证:
  手动复盘记录能被下一个 AI 读取和理解
  AI 通过 opencode run 提交任务被 daemon 正确执行
```

### Phase 5: 安全基座 + 哨兵

```
改动:
  sentinel systemd service  独立审计服务
  auditd 规则              内核级审计
  CONSTITUTION.md          代理宪法
  iptables uid 强制代理     网络逃逸防护

验证:
  哨兵检测越界操作 → notify-send
  nixos-rebuild --rollback 成功回滚
```

### Phase 6: 自进化 + 学习陪伴

```
改动:
  community-pulse skill     社区感知
  usage-analyst skill       参数自适应
  learn-companion skill     学习陪伴

验证:
  社区 RSS 每周摘要无误
  参数自适应不越过安全下限
```

---

## 18. 参考架构与先前艺术

### 直接参考 (已验证的生产系统)

| 项目 | Stars | 核心贡献 |
|------|-------|---------|
| **stereOS** | 478 | admin/agent 用户隔离、受限 shell、Nix daemon 排除 |
| **nixos-hermes** | 3 | 裸金属 agent 主机、StateDirectory、activation scripts、ZFS |
| **AEGIS** | 360 | 5 阶段管道、9 维异常检测、SHA-256 审计链 — Sentinel 直接模板 |
| **PEA 论文** | arXiv:2604.23646 | 三权分离架构、6 个形式化安全定理、形式化验证 |
| **Agentix** | 新 | patch-propose-approve 交互模式 |

### 博弈论与多智能体研究

| 研究 | 发现 | 我们的采纳 |
|------|------|-----------|
| **LLM Wardens** | 典狱官 agent 能减半攻击成功率 (65%→30%) | Sentinel 作为独立观察者 |
| **Enforcement Agent** | 多个弱监管 > 一个强监管 (0→7.4%→26.7%) | 4 层独立观察 |
| **Asymmetric Actor-Critic** | 小模型 critic 能有效监督大模型 actor | Sentinel 用纯规则，比小模型更强 |
| **Multi-Agent Debate** | 辩论提升推理正确性，减少幻觉 | 角色间交叉验证 |
| **PEA Ablation** | 移除 Authorization 层 = 最大单机制安全损失 (34.8%攻击率) | Sentinel 是最重要单层 |

### Agent 框架参考

| 框架 | Stars | 关键模式 |
|------|-------|---------|
| **Hermes-agent** | 165k | Profile 隔离、curator 生命周期、自主技能创建、FTS5 会话搜索 |
| **CrewAI** | 52k | Hierarchical Manager pattern、Guardrails |
| **MetaGPT** | 68k | SOP-based 角色分配、QA Engineer = Sentinel 原型 |
| **AutoGen** | — | 可对话 agent、GroupChatManager |
| **Goose CLI** | 45k | Extensions trait (模块化)、MCP 标准 |
| **Letta Code** | — | 双阶段学习、记忆块、Git-backed memory |

### 实战验证的工具

| 工具 | 角色 | 实战发现 |
|------|------|---------|
| **opencode** (v1.15+) | 主力 AI agent | `opencode serve` 提供 headless daemon，`opencode run --attach` 用于非交互任务提交，`opencode agent create` 定义角色和权限。已在本项目 main 分支长期使用，DeepSeek V3/V4 Flash 后端。 |
| **Claude Code** (v2.1+) | AI 执行引擎 | `claude --print --allowedTools "Read,Edit,Bash" --permission-mode bypassPermissions` 可用于 AI 级复杂任务的非交互执行。支持 `--output-format json` 结构化结果。`--max-budget-usd` 可控制单次任务成本。 |
| **cc-switch** | 提供商桥接 | 通过 `ANTHROPIC_BASE_URL=http://127.0.0.1:15721` 代理 DeepSeek API 到 Claude Code，已在本项目验证可用。 |
| **`.agents/` 知识体系** | 经验积累 | retros + known-issues + skills 三层结构已在 main 分支验证有效。AI 通过复盘记录跨会话传递经验。 |

### 安全工具参考

| 工具 | Stars | 应用 |
|------|-------|------|
| **AEGIS** | 360 | 哨兵 5 阶段管道 + 9 维检测模板 |
| **AgentGuard (numbergroup)** | 101 | 纯规则模式匹配，无 ML 可攻击面 |
| **GuardianAgent** | 11 | 4 层防御运行时 |
| **vulnix** | 770 | Nix Store CVE 扫描 |
| **agent-sandbox.nix** | 86 | bubblewrap 声明式沙箱 |

### NixOS 生态参考

| 项目 | Stars | 学习点 |
|------|-------|--------|
| **impermanence** | 1.8k | 声明式持久化 |
| **vulnix** | 770 | CVE 扫描 |
| **mcp-nixos** | 646 | AI-NixOS 桥梁 |
| **Agentix** | 新 | patch 提案工作流 |
| **claudebox** | 46 | Claude Code 沙箱 |

---

## 19. 术语表

| 术语 | 定义 |
|------|------|
| **PEA** | Policy-Execution-Authorization — 三权分离安全架构 (arXiv:2604.23646) |
| **DAC** | Discretionary Access Control — Linux 用户/组/权限模型 (chmod/chown) |
| **MCP** | Model Context Protocol — AI agent 与外部工具通信的标准协议 |
| **Skill** | Agent Skills Standard (agentskills.io) — 跨 agent 的可移植技能描述格式 |
| **Generation** | NixOS 的不可变系统快照，每次 rebuild switch 产生一个 |
| **Impermanence** | NixOS 社区模块，声明式管理持久化 vs 临时状态 |
| **agenix** | NixOS 的 age 加密密钥管理器 |
| **Constitutional AI** | Anthropic 的宪法式 AI 对齐方法 (arXiv:2212.08073) |
| **Lethal Trifecta** | Simon Willison 的安全模型：私有数据 + 不可信内容 + 外部通信 = 可利用 |
| **Activity Log** | AI 操作的 JSONL 审计日志 (activity.jsonl) |
| **Restic Snapshot** | 操作前自动创建的文件级快照 |
| **FTS5** | SQLite 全文搜索引擎 (gno 使用) |
| **RAG** | Retrieval-Augmented Generation — 检索增强生成 |
| **HMAC Chain** | 每个日志条目 hash 链到前一条，防篡改 (参考 Bernstein) |
| **Auditd** | Linux 内核级审计子系统 |
| **AEGIS** | Agent Guard & Integrity System — 开源 AI agent 防火墙 |
```

---

## 20. 已知问题与待验证假设

> 本章记录蓝图中尚未验证、存在争议或明显过度设计的部分。  
> 不是为了否定设计，而是为后续 AI 和人类提供参考：哪些已验证，哪些仍是假设。  
> 此章节会随实践推进持续更新（每次修正补充新发现的问题）。

### 缺失设计

| 问题 | 说明 | 严重程度 |
|------|------|---------|
| **上下文投递设计** | 蓝图设计了安全、角色、自进化、经验管道，但没有设计"Agent 每次工作时信息如何流向它"——从哪里加载什么、按什么顺序、任务完成后怎么写回。参考 "Everything is Context" 论文的 Constructor → Updater → Evaluator 管道。 | 高 |
| **三层记忆映射** | 蓝图第 10 节经验管道有 4 级积累，但没有显式映射到论文的 History/Memory/Scratchpad 三层模型。git commit history 是 History，.agents/knowledge/ 是 Memory，git worktree 是 Scratchpad——但蓝图没有这样命名和设计。 | 中 |
| **Scratchpad 生命周期** | git worktree 被当作"并行工作目录"（第 7 节已补），但没有完整的生命周期设计——何时归档、何时清除、磁盘空间回收策略。 | 中 |
| **Sentinel 部署策略** | 哨兵与 ai-agent 的启动顺序、失败回退、网络断开时的行为未定义。 | 低 |

### 过度设计

| 问题 | 说明 | 严重程度 |
|------|------|---------|
| **5 用户 × 4 组** | 多用户隔离在单用户开发机上可能不必要。OpenCode agent 体系（`opencode agent create` + permission rules）可替代大部分角色分离需求。v2.1 已补充 `ai-code` 单用户替代方案。 | 中 |
| **Sentinel HMAC 审计链** | 单用户场景下，OpenCode 的 permission rules + git diff 审计 + `known-issues.md` 经验积累就已覆盖 90% 的安全需求。独立 uid + HMAC 链 + 9 维异常检测的工程成本较高，收益在单用户场景下有限。 | 低 |
| **iptables uid 强制代理** | 强制 `uid=1001` 只能走 `lo` 接口再通过 cli-proxy-api 出站——这对于通过 Clash 走代理的单用户机器过于复杂。直接在 Agent 的 shell 环境中设 `http_proxy` 即可。 | 低 |
| **CONSTITUTION.md 独立文件** | 宪法内容可以直接放在 BLUEPRINT.md 或 AGENTS.md 中，不需要单独文件。 | 低 |

### 未验证的工具

| 工具 | 蓝图中的用途 | 实际可用性 |
|------|------------|-----------|
| **gno** (FTS5+RAG+MCP) | 本地知识引擎，用于 FTS5 索引、知识检索 | 未验证是否在 nixpkgs 中，且是否维护活跃 |
| **organize-tool** | 文件规则整理引擎 | 需要手写 derivation，可能不必要（已有更成熟的方案） |
| **vulnix** | CVE 扫描 | 已知可用，但有性能问题（扫描 36GB store 耗时较长） |
| **localgpt / Honcho** | 本地 AI 推理、记忆层 | 未验证是否维护活跃，可能已被更新的工具替代 |

### 未验证的理论

| 假设 | 说明 | 验证方式 |
|------|------|---------|
| PEA 三权分立的安全增益 | arXiv:2604.23646 在多 Agent 服务器上有效，但单用户开发机上的实际增益未量化 | 对比有/无 sentinel 的故障场景 |
| 博弈论制衡的有效性 | 5 角色间的交叉验证能否在实际场景中发现越界行为 | 构造越界场景测试告警率 |
| 自进化四层边界的可执行性 | 自构建/自扩展/自适应/不可触碰的四层划分在实际 AI 工作流中能否被执行 | 试运行一个自进化周期 |
| **信息边界理论** | 个体差异是信息流动不对称的结果，当内部循环速度 > 跨边界速度时，集合产生独立性 | 构造不同信息流动速度的场景，观察独立性变化 |
| **亲疏远近模型** | 圈层结构影响交互行为，不同距离不同交互方式 | 设计多 MEOW 协作场景，验证信任机制 |
| **涌现个体性** | 个体性通过交互历史涌现，从预设开始发展 | 追踪 MEOW 的行为模式演化 |
| **宪法稳定性** | 博弈论宪法能约束行为，满足激励相容、子博弈完美、纳什均衡 | 设计违反宪法的场景，验证惩罚机制 |

### 当规模增长时需要考虑

| 场景 | 当前方案 | 推荐演进 |
|------|---------|---------|
| 复盘 100+ 篇 | grep + frontmatter 搜索 | SQLite + FTS5 结构化索引 |
| 需要语义检索 | 无 | 向量数据库（chroma/pinecone 等） |
| 需要外部信息整合 | 手动 | GitHub API 自动抓取 + RSS |
| Agent 上下文窗口压力 | 手动选择知识文件 | RAG 工具自动检索相关上下文 |
| 文件系统容量压力 | ext4（无压缩/快照） | btrfs 透明压缩 + 快照回滚（至少除 /tmp 外所有挂载点） |

> 此节会随实践持续更新。每次在验证过程中发现新问题时，追加到对应分类下。

```
# 参考实现
github.com/papercomputeco/stereOS          — admin/agent 用户隔离
github.com/rzp-labs/nixos-hermes           — 裸金属 agent 主机
github.com/Justin0504/Aegis                 — 5 阶段 Sentinel 模板
github.com/archie-judd/agent-sandbox.nix    — bubblewrap 沙箱
github.com/numtide/claudebox               — Claude Code 沙箱
github.com/Beach-Bum/Agentix                — patch 提案工作流

# 博弈论/安全研究
arxiv.org/abs/2604.23646                   — PEA 架构
arxiv.org/abs/2605.08321                   — LLM Wardens
arxiv.org/abs/2505.24201                   — SentinelAgent
arxiv.org/abs/2212.08073                   — Constitutional AI

# Agent 框架
github.com/NousResearch/hermes-agent        — 技能创建+curator
github.com/crewAIInc/crewAI                 — Hierarchical Manager
github.com/FoundationAgents/MetaGPT         — SOP-based 角色分配
github.com/aaif-goose/goose                 — Extensions trait

# 生态工具
github.com/utensils/mcp-nixos               — MCP NixOS 桥
github.com/nix-community/vulnix             — CVE 扫描
github.com/nix-community/impermanence       — 声明式持久化
github.com/tfeldmann/organize               — 文件规则引擎
github.com/gmickel/gno                      — 本地知识引擎
github.com/plastic-labs/honcho              — Agent 记忆层
github.com/numbergroup/AgentGuard           — 纯规则 injection 防护
```

---

## 21. NixMEOW 系统设计

> **状态**: 理论框架，待验证
> **来源**: 2026-06-02 探讨性对话

### MEOW 的本质定义

> **MEOW = 能力清单 + 遗传规则 + 运行状态**

这不是简单的文件目录，而是一个**活的、社会化的、有能力的实体**。

#### 四维能力模型

| 维度 | 含义 | 对应内容 |
|------|------|---------|
| **M**emory (记忆) | 跨会话状态、复盘记录 | `retros/`, `known-issues.md` |
| **E**xperience (经验) | 决策记录、踩坑经验 | `decisions/`, `conventions.md` |
| **O**peration (操作) | 技能、脚本、工具配置 | `skills/`, `config/` |
| **W**isdom (智慧) | 架构知识、最佳实践 | `architecture.md` |

#### 关键洞察

**文件只是能力的载体，能力才是本质**

- 一个能力可能由多个文件组成（例如 "NixOS rebuild" 能力 = rebuild 技能 + NixOS 知识 + 架构知识）
- 一个文件可能服务于多个能力（例如 `known-issues.md` 服务于多个技能）
- 继承一个能力 = 继承它的载体 + 它的依赖关系

#### MEOW 的三种状态

| 状态 | 描述 | 存储位置 |
|------|------|---------|
| **静态状态** | 能力清单、遗传规则、边界配置 | `manifest.json` |
| **持久状态** | 经验、记忆、知识 | `knowledge/`, `retros/` |
| **运行状态** | 当前任务、会话上下文、进行中的请求 | 内存 / 临时文件 |

### 与现有架构的关系

NixMEOW 系统是对现有五层 × 五角色架构的**知识组织层补充**：

```
第 4 层: 用户生活层
第 3 层: 系统运营层
第 2.5 层: 自进化层
第 2 层: Agent 运行时
第 1 层: 协议与感知
第 0 层: 安全基座
        ↑
    NixMEOW: 知识/能力组织层（补充）
```

### 待验证问题

| 问题 | 说明 | 验证方式 |
|------|------|---------|
| MEOW 的最优粒度 | 一个 MEOW 应该包含多少能力？ | 实验不同粒度的 MEOW，观察协作效率 |
| 继承的深度限制 | 继承链应该有多长？ | 测试多层继承的复杂度和维护成本 |
| 能力的组合爆炸 | 大量能力如何管理？ | 设计能力索引和检索机制 |

---

## 22. 信息边界理论

> **状态**: 哲学洞察，待形式化
> **来源**: 2026-06-02 探讨性对话

### 核心命题

> "个体差异是信息流动不对称的结果"
> "当内部信息循环速度 > 跨边界速度时，集合产生独立性"

这是一个**信息热力学**的观点：MEOW 就像一个耗散结构，通过内部信息循环维持低熵状态（有序的知识体系），通过跨边界信息交换与环境互动。

### 信息流动的三个维度

| 维度 | 内部 | 跨边界 | 独立性条件 |
|------|------|--------|-----------|
| **速度** | v_in（内部循环） | v_out（跨边界交换） | v_in >> v_out |
| **密度** | ρ_in（内部信息密度） | ρ_out（跨边界信息密度） | ρ_in >> ρ_out |
| **方向** | 循环（记忆↔经验↔能力） | 交换（请求↔响应） | 循环 > 交换 |

### 边界的本质

边界不是"墙"，而是**信息流动的阻力梯度**：

```
       阻力
         ↑
         │     ╭─────── 家族圈（阻力小）
         │    ╱
         │   ╱
         │  ╱   ╭───── 社群圈（阻力中）
         │ ╱   ╱
         │╱   ╱
         ┼───╱──────── 陌生圈（阻力大）
         └──────────────→ 距离
```

**亲疏远近** = 阻力梯度的形状

### 热力学类比

MEOW 是一个**耗散结构**：

- 它通过内部信息循环维持低熵状态（有序的知识体系）
- 它通过跨边界信息交换与环境互动
- 当内部循环足够快，它就能抵抗外部扰动，维持"个性"
- 如果内部循环变慢（知识陈旧、经验固化），MEOW 就会"老化"——失去活力，容易被外部信息"同化"

### 串味的本质

"串味" = 信息边界模糊化

- 当两个 MEOW 之间的信息流动太快、太自由，它们就会**融合**——失去独立性，变成一个 MEOW
- 隔离机制的本质：控制信息流动速度，维持个体边界

### 待形式化

| 概念 | 需要形式化的内容 | 可能的数学工具 |
|------|-----------------|---------------|
| 信息流动速度 | 单位时间内传递的信息量 | 信息论、熵 |
| 边界阻力 | 跨边界信息交换的成本 | 博弈论、机制设计 |
| 独立性度量 | 如何量化一个 MEOW 的"个性" | 复杂系统、网络科学 |

---

## 23. 社会化交互模型

> **状态**: 概念模型，待设计
> **来源**: 2026-06-02 探讨性对话

### 圈层结构

```
                    ┌─────────────┐
                    │   自己      │  核心圈
                    │  (Self)     │  完全信任
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
        ┌─────┴─────┐ ┌────┴────┐ ┌────┴─────┐
        │  父 MEOW  │ │ 子 MEOW │ │ 子 MEOW  │  家族圈
        │ (Parent)  │ │ (Child) │ │ (Child)  │  强信任
        └─────┬─────┘ └─────────┘ └──────────┘
              │
    ┌─────────┼─────────┐
    │         │         │
┌───┴───┐ ┌───┴───┐ ┌───┴───┐
│兄弟   │ │兄弟   │ │兄弟   │  社群圈
│(Peer) │ │(Peer) │ │(Peer) │  有限信任
└───────┘ └───────┘ └───────┘
```

### 圈层定义

| 圈层 | 关系 | 信息流动速度 | 交互方式 | 信任度 |
|------|------|------------|---------|--------|
| **核心圈** | 自己 | ∞（瞬时） | 直接访问 | 100% |
| **家族圈** | 父子 | 快 | 委托/继承 | 80% |
| **社群圈** | 兄弟 | 中等 | 请求/响应 | 50% |
| **陌生圈** | 未知 | 慢/无 | 广播/询问 | 0% |

### 交互行为矩阵

| 从\到 | 核心圈 | 家族圈 | 社群圈 | 陌生圈 |
|-------|--------|--------|--------|--------|
| **核心圈** | 直接读写 | 委托读写 | 请求只读 | 广播询问 |
| **家族圈** | - | 直接读写 | 请求只读 | 广播询问 |
| **社群圈** | - | - | 请求只读 | 广播询问 |
| **陌生圈** | - | - | - | 广播询问 |

### 交互协议

#### 核心圈：直接访问
```
MEOW_A → 直接读写 → MEOW_A的能力
```

#### 家族圈：委托/继承
```
子MEOW → 委托请求 → 父MEOW → 路由/响应
```

#### 社群圈：请求/响应
```
兄弟MEOW_A → 请求能力 → 兄弟MEOW_B → 响应
```

#### 陌生圈：广播/询问
```
MEOW → 广播请求 → 所有已知MEOW → 谁能响应？
```

### 待设计

| 设计点 | 需要设计的内容 | 约束条件 |
|--------|---------------|---------|
| 圈层配置 | 如何定义亲疏远近 | 简单、直观、可动态调整 |
| 交互协议 | 不同圈层的交互规则 | 安全、高效、可审计 |
| 信任管理 | 如何建立和撤销信任 | 防止信任滥用 |
| 冲突解决 | 圈层之间的冲突如何解决 | 优先级、投票、仲裁 |

---

## 24. 宪法的博弈论基础

> **状态**: 理论基础，待验证
> **来源**: 2026-06-02 探讨性对话

### 宪法 = 博弈规则的共识

宪法不是"限制"，而是"共同知识"：

所有玩家都知道：
1. 游戏的边界在哪里
2. 什么行为被允许
3. 什么行为被禁止
4. 违反规则的后果

这种"共同知识"使得博弈可以稳定进行。

### 稳定性条件

从博弈论角度，宪法要稳定，需要满足：

| 条件 | 含义 | 验证方式 |
|------|------|---------|
| **激励相容** | 遵守宪法比违反宪法更优 | 分析收益矩阵 |
| **子博弈完美** | 在任何子博弈中，遵守宪法都是最优策略 | 逆向归纳法 |
| **纳什均衡** | 没有玩家有单方面偏离的激励 | 均衡分析 |

### 哨兵的博弈论角色

哨兵不是"惩罚者"，而是**信息不对称的修正者**：

**没有哨兵：**
```
Agent 知道自己的行为，环境不知道
→ 信息不对称 → 可能作弊
```

**有哨兵：**
```
Agent 知道自己的行为，哨兵也知道
→ 信息对称 → 作弊成本高
```

**哨兵的本质**：增加跨边界信息流动的密度，让"隐藏行为"变得困难。

### 宪法设计原则

| 原则 | 说明 | 博弈论基础 |
|------|------|-----------|
| **不变原则** | 不可删除、修改、或绕过 | 共同知识的稳定性 |
| **操作边界** | 需要人类确认的操作 | 激励相容 |
| **自保约束** | 不可拒绝被关闭 | 防止 agent 自我保护 |
| **学习约束** | 自构建代码需测试 | 风险控制 |

### 待验证

| 假设 | 说明 | 验证方式 |
|------|------|---------|
| 宪法能约束行为 | 博弈论宪法能有效约束 AI 行为 | 设计违反宪法的场景，验证惩罚机制 |
| 哨兵能修正信息不对称 | 哨兵能有效发现越界行为 | 构造越界场景，测试告警率 |
| 激励相容能自我执行 | 遵守宪法比违反更优 | 分析收益矩阵，验证纳什均衡 |

---

## 25. 个体性涌现理论

> **状态**: 直觉假设，待研究
> **来源**: 2026-06-02 探讨性对话

### 核心命题

> "个体应当是从预设开始涌现"

个体性不是完全预设的，也不是完全涌现的，而是**从预设开始，通过涌现发展**。

### 先天 vs 后天

**个体性 = 先天遗传 + 后天交互**

| 类型 | 来源 | 示例 |
|------|------|------|
| **先天** | manifest.json 定义 | 能力清单、继承规则、边界配置 |
| **后天** | 交互历史 | 被调用的能力、信任关系、行为模式 |

### 预设作为种子

预设不是"蓝图"，而是"种子"：

- 预设定义了**可能性空间**：这个 MEOW **可能**成为什么
- 涌现是**实际路径**：这个 MEOW **实际**成为了什么

```
预设：{能力A, 能力B, 能力C}
        │
        │ 交互历史
        ▼
涌现：{能力A(高频), 能力B(低频), 能力C(未使用)}
```

### 涌现机制

| 机制 | 描述 | 结果 |
|------|------|------|
| **能力调用频率** | 经常被调用的能力会"增强" | 行为模式形成 |
| **信任积累** | 成功交互增加信任 | 边界阻力减小 |
| **行为模式** | 重复的行为模式形成"习惯" | 可预测性增加 |
| **声誉** | 历史交互记录形成"信誉" | 社会地位形成 |

### 个体性的度量

如何量化一个 MEOW 的"个性"？

| 度量维度 | 描述 | 计算方式 |
|---------|------|---------|
| **能力分布** | 各种能力的权重 | 调用频率统计 |
| **行为熵** | 行为的可预测性 | 信息熵计算 |
| **信任网络** | 与其他 MEOW 的信任关系 | 图论分析 |
| **历史长度** | 积累的经验多少 | 时间跨度 |

### 涌现的可观测性

如何观测一个 MEOW 的"个体性"在涌现？

1. **行为模式的统计**：能力调用频率、交互模式
2. **信任关系的演化**：信任度的变化
3. **声誉的积累**：历史交互记录
4. **独特性的形成**：与其他 MEOW 的差异

### 待研究

| 问题 | 说明 | 研究方向 |
|------|------|---------|
| 预设的最优边界 | 预设应该定义多少？ | 复杂系统、涌现理论 |
| 涌现的可预测性 | 从预设能预测涌现的方向吗？ | 混沌理论、非线性动力学 |
| 涌现的终止条件 | 涌现会停止吗？ | 稳态理论、吸引子 |
| 多MEOW生态 | 群体中个体性的分布 | 群体智能、演化博弈 |

---

## 附录 B: 与已知方案的最终对比

| 维度 | Agentix | stereOS | nixos-hermes | Hermes | CrewAI | **NixMEOW AI** |
|------|---------|---------|-------------|--------|--------|---------------|
| AI 安全模型 | 应用层 | 用户隔离 | 单一用户 | profile 隔离 | 无强制 | **用户组 DAC + PEA** |
| 角色体系 | 单一 | 2 角色 | 单一 | 单一 | 文本定义 | **5 角色 × 博弈制衡** |
| 代理宪法 | 无 | 无 | 无 | 无 | 无 | **CONSTITUTION.md** |
| 哨兵 | JSON 审计 | 无 | 无 | 无 | 部分 | **独立 uid + HMAC + 9 维检测** |
| 自进化 | 无 | 无 | curator | curator | 无 | **四层边界 + 经验管道** |
| 文件策略 | 无 | 无 | 无 | 无 | 无 | **每目录 `.ai-rules`** |
| 经验积累 | 无 | 无 | session search | session search | 无 | **4 级管道 (原始→复盘→知识→技能)** |
| 社区监控 | 无 | 无 | 无 | skills hub | 无 | **8 源 RSS + API 矩阵** |
| 网络审计 | 无 | 无 | firewall off | 无 | 无 | **cli-proxy-api + iptables uid** |
| 反幻觉 | 部分 | 无 | 无 | 无 | 无 | **mcp-nixos** |
| Nix 隔离 | 部分 | ✅ | 部分 | 无 | 无 | **allowed-users + sudo 白名单** |
```

