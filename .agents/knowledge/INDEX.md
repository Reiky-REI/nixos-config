# Knowledge Index

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

## 决策索引
| 文件 | 标签 | 状态 |
|------|------|------|
| [nixos-26.05-upgrade-plan.md](decisions/nixos-26.05-upgrade-plan.md) | upgrade, waydroid, gbinder, niri | ⏳ 等待 26.05 正式版 |

## Skill 索引
> 统一入口: `SKILLS.md` — 按场景查找，包含全部技能元信息

| 技能 | 描述 | 适用 |
|------|------|------|
| [nixos-manager](../SKILLS.md#配置管理) | NixOS 配置安全管理 — 修改/验证/提交/应用工作流 | opencode, claude |
| [rebuild](../SKILLS.md#配置管理) | NixOS rebuild 操作指引 — 构建/switch/后台编译/加速 | opencode, claude |
| [secrets](../SKILLS.md#配置管理) | agenix 密钥管理 — 编辑/新增/查看/重加密 | opencode, claude |
| [networking](../SKILLS.md#网络--环境) | 代理/GitHub token/镜像源/SSH 配置 | opencode, claude |

## 复盘索引
完整复盘列表见 [retros/.retros-index.md](retros/.retros-index.md)（共 25 篇）
