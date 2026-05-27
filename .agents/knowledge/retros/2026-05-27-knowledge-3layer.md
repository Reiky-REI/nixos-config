---
date: 2026-05-27
module: .agents/
tags: [知识管理, 工作流, 架构]
related:
  - ../../known-issues.md (去重)
---

# 复盘: 知识库三层架构 + 三级工作流

## 变更

| 操作 | 文件 | 说明 |
|------|------|------|
| doc | `.agents/AGENTS.md` | 新增 `## Map` 显式目录地图 |
| doc | `.agents/AGENTS.md` | 知识体系改为三级工作流（轻量/标准/复杂） |
| doc | `.agents/knowledge/conventions.md` | 新增「复盘格式」frontmatter 模板 + 相关字段规范 |
| doc | `.agents/knowledge/known-issues.md` | 移除重复的「代理与网络」段（已在 skill） |
| doc | `.agents/knowledge/INDEX.md` | 新增 decisions/ + maps/ 扩展目录说明 |
| doc | `.agents/skills/secrets/SKILL.md` | 顶部加引用链接指向 `knowledge/secrets.md` |
| fix | `.agents/knowledge/retros/` | 修复缺 `.md` 后缀的异常文件 |
| dir | `.agents/knowledge/decisions/` | 新建空目录（Layer 3 接口） |
| dir | `.agents/knowledge/maps/` | 新建空目录（Layer 3 接口） |

## 三层设计

| 层 | 内容 | 对谁 |
|---|------|------|
| Layer 1 — 操作层 | 三级工作流（轻量/标准/复杂） | 用户（减少仪式感） |
| Layer 2 — 知识层 | frontmatter 复盘 + 搜索 + 索引 | AI + 用户 |
| Layer 3 — 追溯层 | 决策记录 + 依赖链（空目录占位） | AI（复杂任务时填充） |

## 注意
- 去重从 `known-issues.md` 开始，后续遇到重复内容同步清理
