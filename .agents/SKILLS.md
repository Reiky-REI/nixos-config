# Skills 索引

> 通用技能体系 — OpenCode 和 Claude Code 共用。
> 按场景查找技能，需要时加载对应 `skills/<name>/SKILL.md`。

## 配置管理

| 技能 | 场景 | 适用 |
|------|------|------|
| [nixos-manager](skills/nixos-manager/SKILL.md) | 日常改配置 → build → 提交 | opencode, claude |
| [rebuild](skills/rebuild/SKILL.md) | nixos-rebuild 操作 (build/switch/后台编译/加速) | opencode, claude |
| [secrets](skills/secrets/SKILL.md) | agenix 密钥管理 (编辑/新增/重加密) | opencode, claude |

## 服务管理

| 技能 | 场景 | 适用 |
|------|------|------|
| [dsh](skills/dsh/SKILL.md) | DSH 服务管理 — 启停/排障/Tailscale 远程/端口冲突 | opencode, claude |

## 磁盘 & 维护

| 技能 | 场景 | 适用 |
|------|------|------|
| [disk-cleanup](skills/disk-cleanup/SKILL.md) | 系统磁盘清理 — Nix GC/HM残留/coredump/临时文件 | opencode, claude, codex, dsh, astrabot |

## 网络 & 环境

| 技能 | 场景 | 适用 |
|------|------|------|
| [networking](skills/networking/SKILL.md) | 代理设置、GitHub token、镜像源、SSH | opencode, claude |

## 执行入口

- **OpenCode**: 通过 AGENTS.md 加载，或在 opencode.json 中 enable
- **Claude Code**: 通过 CLAUDE.md 加载，开工前按需读取对应 SKILL.md
