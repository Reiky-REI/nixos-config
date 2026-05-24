# NixMEOW AI-Native 系统 · 完整蓝图

> 版本: v2.0  
> 本文档是 NixMEOW AI-Native 操作系统设计的 **唯一权威参考**。  
> 整合了生态调研、博弈论分析、实战验证、角色分类、自进化体系。  
> 本文档定义**最终目标**——实现路径见 BOOTSTRAPPER.md，验证标准见 VERIFICATION.md。

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
13. [文件整理与软链接策略](#13-文件整理与软链接策略)
14. [备份路由](#14-备份路由)
15. [systemd 定时器总表](#15-systemd-定时器总表)
16. [完整工具清单](#16-完整工具清单)
17. [实施路线图](#17-实施路线图)
18. [参考架构与先前艺术](#18-参考架构与先前艺术)
19. [术语表](#19-术语表)

---

## 1. 项目愿景

构建一个 **AI-Native 操作系统**。AI 不是外挂的应用层工具，而是操作系统的组成部分。

### 五个维度的 AI 能力

| 维度 | 目标 |
|------|------|
| **系统维护** | AI 管理 NixOS 配置、监控安全漏洞、清理磁盘 |
| **文件管理** | AI 按内容智能分类、去重、软链接保留、路由备份 |
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
  Copilot(副驾驶) · Companion(伴侣) · System Agent(管家) · Explorer(探索者)

第 1 层: 协议与感知
  mcp-nixos · systemd · inotify · swaync · auditd

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

### 角色详细定义

**Copilot (ai-copilot, uid=1011)**
- 定位: 像输入法一样贴身
- 交互: zsh 补全建议、命令纠错、快速问答
- 工具: shell function + opencode --plan 模式
- 权限: 最低。只读 ai-reader 组。不能写任何文件，不能执行任何命令
- 实现: 优先用 zsh history + fzf 增强补全，AI copilot 留接口后续本地小模型

**Companion (ai-companion, uid=1012)**
- 定位: 私人 AI 伴侣
- 交互: CLI 命令或 dedicated tmux 窗口
- 工具: openclaw + gno + ollama
- 权限: 低。读共享目录，写自己知识库。不执行系统命令
- 核心职责: 学习陪伴、知识图谱、**会话后经验记录**

**System Agent (ai-agent, uid=1001)**
- 定位: 后台系统维护者
- 交互: systemd timer 触发，swaync 通知结果
- 工具: opencode (skill 模式) + organize-tool + vulnix + restic
- 权限: 中。受限 sudo + 组共享目录读写
- 核心职责: 文件整理、安全监控、磁盘清理、备份、社区监控

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

---

## 8. 技能矩阵

### 11 个用户技能 + 3 个元技能

**用户生活层 (6 skills)** — 运行在 ai-agent 用户下

| Skill | 触发方式 | 权限边界 | 核心工具 |
|-------|---------|---------|---------|
| file-organizer | watchexec + timer (hourly) | ai-shared 可写目录 | organize-tool, trash-cli, ai-relocate |
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
| knowledge-recorder | 每次 rebuild 后 + 会话结束后 | 按 _template.md 格式 | session recap + 知识更新 |

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
  └── 按 _template.md 格式生成复盘

第 3 级: 知识沉淀 (Curated) — 自动
  ├── gno FTS5 索引所有知识库
  ├── Honcho Dream 管道（可选）→ 发现"surprise"模式
  ├── 匹配已有的 troubleshooting/*.md
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

## 13. 文件整理与软链接策略

### 三级权限模型

```
auto:    ~/Downloads/*  ~/screenshot/*  ~/.cache/ai-agent/*
confirm: ~/documents/** ~/WorkSpace/**   ~/Desktop/*
deny:    ~/.ssh/**      ~/.gnupg/**      ~/Documents/private/**
```

### 软链接保留方案（自建——无现有工具支持）

**调研结论**: organize-tool 的 symlink 方向是错的（在目标目录建软链接，不是原位置）。需自建。

**ai-relocate 工具**:
```python
# 移动文件 → 在原位置留软链接 → 记录到 registry
# {ts, src, dst, symlink_path, expires_at}
```

**symlink-cleaner skill** (定期清理过期软链接):
```bash
# 读取 ~/ai-agent/.symlink-registry.jsonl
# 找到 expires_at < now 的条目 → 删除软链接
```

**每目录配置文件** (organize-tool 不原生支持):

```toml
# ~/Downloads/.organize-rules.toml
[symlink]
enabled = true
keep_days = 30

[auto]
enabled = true
categories = ["documents", "images", "archives"]
```

```toml
# ~/documents/.organize-rules.toml
[symlink]
enabled = false
[auto]
enabled = false
[confirm]
enabled = true
```

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
  ✅ ollama (本地模型)                ✅ opencode (主力 coding)
  🔷 openclaw (后台助手)              🔷 bernstein (多agent编排, 按需)
  ✅ llama-cpp (可选本地推理)

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

安全基座:
  Linux DAC (用户组权限)               auditd (内核级审计)
  systemd cgroups (资源限制)            iptables/nftables (网络强制)
  agenix (密钥管理, 已有)               CONSTITUTION.md (代理宪法)

文件整理:
  🐍 organize-tool (<30行 derivation)   🔧 ai-relocate (自建)
  🔧 .organize-rules.toml parser        🔧 symlink-cleaner

角色间通信:
  🔧 文件通信 (~/ai-agent/tasks/*.jsonl) — Phase 1
  📡 MCP server — Phase 2+ (可选)
```

---

## 17. 实施路线图

### Phase 1: 基础设施 + 用户组

```
改动:
  flake.nix             [修改]  新增 llm-agents + mcp-nixos inputs + 5 个用户+组定义
  modules/services/ai/  [新建]  default.nix, ollama.nix, timers.nix
  home/Reiky-REI/ai/    [新建]  default.nix, skills/default.nix, mcp.nix, companion-dirs.nix
  ~/.config/ai-companion/  [新建]  learn/subjects/_template.md + files/
  新增 5 个 Linux 用户定义

验证:
  nixos-rebuild build --flake /etc/nixos#NixMEOW 零错误
  ollama list 显示 qwen3:4b + nomic-embed-text
  systemctl list-timers | grep ai- 显示 10+ timer
  id ai-agent, id ai-sentinel 确认正确组
  sudo -u ai-agent nixos-rebuild switch → PERMISSION DENIED
```

### Phase 2: Agent 运行时

```
改动:
  modules/services/ai/openclaw-daemon.nix  [新建]  openclaw systemd service
  iptables 规则                             强制 uid 只能走代理

验证:
  systemctl --user status openclaw-gateway 正常
  power-aware: 拔电源 → agent 暂停
  curl google.com (as ai-agent) → 被 iptables REJECT
  curl localhost:7897 (as ai-agent) → 正常
```

### Phase 3: Skills 矩阵

```
改动:
  home/Reiky-REI/ai/skills/  11 个 skill .nix → SKILL.md 生成
  organize-tool derivation
  ai-relocate + symlink-cleaner 脚本

验证:
  ~/.config/opencode/skills/ 包含 11+3 个 SKILL.md
  每个 SKILL.md 有正确 YAML frontmatter
  organize sim 正确分类测试 Downloads
  vulnix --system 正确报告
```

### Phase 4: 安全基座 + 哨兵

```
改动:
  modules/services/ai/sandbox.nix   bubblewrap 声明式沙箱
  home/Reiky-REI/ai/audit.nix      activity.jsonl + restic snapshot
  sentinel-rules.nix               哨兵规则
  CONSTITUTION.md                  代理宪法

验证:
  activity.jsonl 在文件操作后正确写入
  restic snapshots --tag pre-ai-change 显示快照
  sentinel 检测到异常 → notify-send
  nixos-rebuild --rollback 成功回滚
```

### Phase 5: 自进化 + 经验管道

```
改动:
  knowledge-recorder skill
  community-opportunist skill
  usage-analyst skill
  gno 知识引擎集成
  .organize-rules.toml parser

验证:
  rebuild 后自动生成 session recap
  社区 RSS 每周摘要无误
  参数自适应不越过安全下限
```

### Phase 6: 学习陪伴 + 发布

```
改动:
  learn-companion skill
  publisher skill
  ClawHub publish 集成 (可选)

验证:
  learn-companion 能总结学习笔记
  publisher 能自动发布博客
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

## 附录 A: 关键外部参考链接

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

## 附录 B: 与已知方案的最终对比

| 维度 | Agentix | stereOS | nixos-hermes | Hermes | CrewAI | **NixMEOW AI** |
|------|---------|---------|-------------|--------|--------|---------------|
| AI 安全模型 | 应用层 | 用户隔离 | 单一用户 | profile 隔离 | 无强制 | **用户组 DAC + PEA** |
| 角色体系 | 单一 | 2 角色 | 单一 | 单一 | 文本定义 | **5 角色 × 博弈制衡** |
| 代理宪法 | 无 | 无 | 无 | 无 | 无 | **CONSTITUTION.md** |
| 哨兵 | JSON 审计 | 无 | 无 | 无 | 部分 | **独立 uid + HMAC + 9 维检测** |
| 自进化 | 无 | 无 | curator | curator | 无 | **四层边界 + 经验管道** |
| 文件软链接 | 无 | 无 | 无 | 无 | 无 | **自建 ai-relocate** |
| 经验积累 | 无 | 无 | session search | session search | 无 | **4 级管道 (原始→复盘→知识→技能)** |
| 社区监控 | 无 | 无 | 无 | skills hub | 无 | **8 源 RSS + API 矩阵** |
| 网络审计 | 无 | 无 | firewall off | 无 | 无 | **cli-proxy-api + iptables uid** |
| 反幻觉 | 部分 | 无 | 无 | 无 | 无 | **mcp-nixos** |
| Nix 隔离 | 部分 | ✅ | 部分 | 无 | 无 | **allowed-users + sudo 白名单** |
```

