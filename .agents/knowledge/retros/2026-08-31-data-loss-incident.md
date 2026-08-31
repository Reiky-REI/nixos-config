---
id: data-loss-incident
date: 2026-08-31
module: system/data-migration
tags: [data-loss, rsync, webdav, nas, critical-incident]
severity: critical
status: resolved
related: [known-issues.md, skills/disk-cleanup/SKILL.md, AGENTS.md]
---

# 🚨 严重过失复盘: rsync 迁移数据丢失 (2026-08-31)

## 事故概述
执行 NAS 数据迁移时，使用 `rsync -av --remove-source-files` 将本地数据迁移到 NAS WebDAV，
rsync 写入 WebDAV 静默失败，但本地数据已被删除，导致 **7.2G 数据永久丢失**。

## 丢失数据明细

| 目录 | 大小 | 内容 | 可恢复？ |
|------|------|------|----------|
| `~/WorkSpace/models` | 6.5G | qwen3-embedding-0.6b-q8 + qwen3-reranker-0.6b-q8 | ❌ 需重新下载 |
| `~/Pictures` | 455M | Wallpapers(397M) + icons(59M) + 头像(204K) | ❌ 需从其他来源恢复 |
| `~/Documents` | 282M | office 文档 | ❌ 需从其他备份恢复 |

## 事故时间线

1. 15:34 执行迁移脚本
2. rsync 尝试写入 WebDAV → 静默失败（无报错）
3. 脚本执行 `rm -rf` 删除本地目录
4. 脚本创建符号链接指向空 NAS 目录
5. 用户发现桌面壁纸消失
6. 排查确认数据丢失

## 根因分析

### 直接原因
1. **rsync `--remove-source-files` 先删后确认** — 写入失败不回滚已删除的文件
2. **WebDAV 写入不可靠** — rclone mount WebDAV 对某些操作支持不完整
3. **迁移脚本没有验证写入结果** — 没有检查目标目录是否有文件

### 根本原因
AI 在执行数据迁移时，没有遵守安全操作规范：
- 没有先验证 WebDAV 写入能力
- 没有分步执行（先复制验证，再删除）
- 没有考虑写入失败的情况

## 铁律（已写入所有关键位置）

```
⛔ 禁止: rsync --remove-source-files 到远程/NAS/WebDAV

正确流程:
1. rsync 复制（不加 --remove-source-files）
2. 验证: ls 远程目录 | wc -l  对比本地文件数
3. 验证: du -sh 远程目录  对比本地大小
4. 确认一致后，再手动 rm 本地文件
5. 绝不要一条命令同时"复制+删除"
```

## 已更新的文件

| 文件 | 更新内容 |
|------|----------|
| `.agents/AGENTS.md` | 新增纪律8: 数据迁移铁律 |
| `.agents/AGENTS.md` | 常见陷阱新增: WebDAV 写入不可靠 |
| `.agents/knowledge/known-issues.md` | 新增严重过失条目 |
| `.agents/knowledge/INDEX.md` | 新增铁律速查表 |
| `.agents/skills/disk-cleanup/SKILL.md` | 顶部新增醒目警告 |

## 教训

1. **永远不要用 `rsync --remove-source-files` 到远程** — 写入失败会静默丢失数据
2. **WebDAV 写入不可靠** — 优先用 SMB/NFS
3. **数据迁移必须分两步** — 先复制验证，再手动删除
4. **任何删除操作前先备份** — `cp -r` 到安全位置再操作
5. **AI 执行删除操作前必须确认写入成功** — 不能静默失败
