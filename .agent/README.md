# .agent 工作流中心

AI Agent 与人类协作的系统配置、需求规划、执行记录中心。

## 📂 目录结构说明

```
.agent/
├── README.md                      ← 本文件
├── INDEX.md                       ← 全量检索索引（自动生成）
├── WORKFLOW.md                    ← 工作流规范
│
├── knowledge/                     ← 知识库（长期有效）
│   ├── architecture.md
│   ├── conventions.md
│   ├── secrets.md
│   └── INDEX.md
│
├── config/                        ← 配置脚本
│   ├── env.sh
│   ├── rebuild.sh
│   └── token (gitignored)
│
├── plans/                         ← 需求和计划（按日期树）
│   ├── TEMPLATE.md                ← 计划模板
│   ├── INDEX.md                   ← 需求池索引
│   └── YYYY/MM/
│       ├── DD-<name>-需求.md      ← 需求文档
│       └── DD-<name>-plan.md      ← 执行计划
│
└── sessions/                      ← 执行日志（按日期树）
    ├── TEMPLATE.md                ← 会话模板
    ├── INDEX.md                   ← 会话索引
    └── YYYY/MM/
        └── DD-session.md          ← 日志记录
```

## 🔄 核心工作流

### 1️⃣ 需求阶段
- 文件：`.agent/plans/YYYY/MM/DD-<name>-需求.md`
- 由用户编写，描述问题、目标、约束条件

### 2️⃣ 规划阶段
- 文件：`.agent/plans/YYYY/MM/DD-<name>-plan.md`
- 由 AI 根据需求生成详细执行计划（步骤表、影响范围、验证方式）

### 3️⃣ 执行阶段
- 文件：`.agent/sessions/YYYY/MM/DD-session.md`
- 由 AI 在执行过程中记录时间线、提交 hash、问题反馈
- **一个 Session 可包含多个 Plan**

### 4️⃣ 提交和存档
- 执行完成后，Session 中记录关键提交
- Plan 文件留作参考，标记为已完成

## 🔍 检索系统

### 快速查找
```bash
# 查看今天的需求
cat .agent/plans/$(date +%Y/%m)/$(date +%d)-*-需求.md

# 查看最近执行的会话
ls -lt .agent/sessions/*/*/*-session.md | head -5

# 搜索特定主题
grep -r "fcitx5" .agent/plans/
grep -r "secrets" .agent/sessions/
```

### 自动索引
- `plans/INDEX.md` — 按主题、状态、日期分类的需求索引
- `sessions/INDEX.md` — 按日期、关键词分类的执行记录

## 📋 文件命名约定

**Plans:**
- 需求文档：`DD-<category>-需求.md` (如：`24-fcitx5-需求.md`)
- 执行计划：`DD-<category>-plan.md`

**Sessions:**
- 日志文件：`DD-session.md` (每天一个文件)

**Categories（常用）:**
- `cleanup` — 代码清理、重构
- `feature` — 新功能开发
- `bugfix` — 缺陷修复
- `docs` — 文档编写
- `refactor` — 模块重构

## 🚀 使用示例

### 创建新需求
```bash
cat > .agent/plans/2026/05/25-theme-需求.md << 'EOF'
# 需求: 2026-05-25 主题统一

## 问题描述
catppuccin 子模块兼容性问题，多个主题无法应用

## 期望结果
- 主题一致性
- 文档记录问题

## 约束
- 不修改上游 catppuccin
EOF
```

### AI 生成计划
```bash
# 用户调用 AI 生成 plan
# AI 输出 .agent/plans/2026/05/25-theme-plan.md
```

### 执行和记录
```bash
# AI 执行完毕后创建
cat > .agent/sessions/2026/05/25-session.md << 'EOF'
# Session: 2026-05-25

## 执行记录
| 时间 | 步骤 | 状态 |
|------|------|------|
| 10:00 | 修复 catppuccin alacritty | ✅ |
| 10:15 | 验证 rebuild | ✅ |

## 关键提交
- abc1234: fix: restore catppuccin theme support
EOF
```

## 🔗 关联查看

- **架构设计**：见 `knowledge/architecture.md`
- **编码约定**：见 `knowledge/conventions.md`
- **密钥管理**：见 `knowledge/secrets.md`
- **系统维护**：见 `knowledge/INDEX.md`
- **工作流细节**：见 `WORKFLOW.md`

