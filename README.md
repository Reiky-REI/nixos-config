# NixMEOW AI-Native · 蓝图分支

> 实验性分支，用于设计 AI-Native NixOS 架构。  
> **永不并入 main**。

## 结构

```
.agent/                         ← AI 架构蓝图
  ├── blueprint/                ← 核心设计文档
  │   ├── BLUEPRINT.md          ← 系统蓝图（五层×五角色 + PEA）
  │   ├── BOOTSTRAPPER.md       ← AI 执行手册
  │   ├── VERIFICATION.md       ← 验证标准
  │   └── verify.sh             ← 验证脚本
  ├── knowledge/                ← 经验积累（初始空框架）
  ├── config/                   ← 工作流工具
  │   ├── commit.sh             ← AI 提交脚本
  │   ├── env.sh                ← 代理/密钥环境
  │   └── rebuild.sh            ← 构建脚本
  ├── plans/                    ← 未来计划
  ├── sessions/                 ← 会话记录
  └── README.md                 ← 给 AI 的入口
```

## 起点

要基于此蓝图构建系统时，从 `.agent/STARTUP.md` 开始。

## 实验状态

此分支修正于 2026-05-28，融入了 `opencode serve`、`claude --print`、git worktree 等实战发现。
