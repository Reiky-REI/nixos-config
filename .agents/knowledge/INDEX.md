# Knowledge Index

## Agent 上下文加载指南

Agent 每次启动时，按以下顺序加载知识：

1. **读 INDEX.md**（本文件）→ 确定需要读哪些文件
2. **读 architecture.md** → 理解系统结构和模块边界
3. **读 conventions.md** → 确认编码规范和工作流
4. **按需读 known-issues.md** → 排查当前任务相关的问题
5. **按需读 retros/ 或 decisions/** → 检索历史复盘和决策记录

任务完成后：
- 有新发现 → 写复盘到 `retros/`
- 有新踩坑 → 追加到 `known-issues.md`
- 有新约定 → 更新 `conventions.md`
- 代码变更 → `git commit`

> 未来当知识查询效率遇到瓶颈时，可评估引入 SQLite（结构化查询）、向量数据库（语义检索）或 RAG 工具（上下文增强）。

## 知识文件
| 文件 | 标签 | 读它的时机 |
|------|------|-----------|
| architecture.md | 架构, 分层, 模块边界 | 理解模块归属、系统 vs home 边界时 |
| conventions.md | 风格, 命名, 环境变量, git | 写代码前确认格式和命名规范 |
| secrets.md | agenix, 加密, 密钥 | 管理加密密钥、新增用户时 |
| known-issues.md | 已知问题, 排障, 兼容性 | 遇到报错、排查问题时 |

## 知识扩展目录
| 目录 | 用途 | 何时写入 |
|------|------|---------|
| `retros/` | 变更复盘 | 标准/复杂任务完成后 |
| `decisions/` | 决策记录（为什么这么选） | 复杂任务需做选型、待办计划时 |
| `maps/` | 依赖链 / 模块关系图 | 遇到复杂依赖关系时 |
| `requests/pending/` | 系统变更申请（待处理） | 其他 AI 提交申请时 |
| `requests/archive/` | 已处理申请归档 | 复盘完成后 |

## 决策索引
| 文件 | 标签 | 日期 |
|------|------|------|
| [niri-focus-ring-transparent-overlay.md](decisions/niri-focus-ring-transparent-overlay.md) | niri, focus-ring, transparent, opacity, overlay, electron | 2026-05-27 |
| [nixos-26.05-upgrade-plan.md](decisions/nixos-26.05-upgrade-plan.md) | upgrade, nixos-26.05, waydroid, gbinder, niri | 2026-05-27 |

## Skill 索引
> 统一入口: `SKILLS.md` — 按场景查找，包含全部技能元信息

| 技能 | 描述 | 适用 |
|------|------|------|
| [nixos-manager](../SKILLS.md#配置管理) | NixOS 配置安全管理 — 修改/验证/提交/应用工作流 | opencode, claude |
| [rebuild](../SKILLS.md#配置管理) | NixOS rebuild 操作指引 — 构建/switch/后台编译/加速 | opencode, claude |
| [secrets](../SKILLS.md#配置管理) | agenix 密钥管理 — 编辑/新增/查看/重加密 | opencode, claude |
| [dsh](../SKILLS.md#服务管理) | DSH 服务管理 — 启停/排障/Tailscale 远程/端口冲突 | opencode, claude |
| [networking](../SKILLS.md#网络--环境) | 代理/GitHub token/镜像源/SSH 配置 | opencode, claude |

## 复盘索引
完整复盘列表见 [retros/.retros-index.md](retros/.retros-index.md)（共 58 篇）
