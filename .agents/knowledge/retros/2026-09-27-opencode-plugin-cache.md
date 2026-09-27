---
date: 2026-09-27
module: home/Reiky-REI/tools/opencode.nix, home/Reiky-REI/tools/opencode-edit-backup.js
tags: [opencode, v2, plugin, bun, systemd, cache, patch]
layer: home
severity: medium
related:
  - ../known-issues.md (OpenCode v2 插件/配置迁移)
  - 2026-09-26-opencode-v2-nas-desktop.md (edit-backup V2 迁移)
experience:
  - "V2 插件源码更新后仍报 Missing key at default, 要区分源码是否错误与长驻服务是否缓存旧模块; 重启服务后插件 ID 恢复可见"
  - "全局插件软链 + 项目级同源插件会在该项目中加载两次; 只保留一个自动发现入口"
  - "对长驻 OpenCode 服务, 将插件源码与部署目录接入 systemd.path, 变更后只在服务运行时自动重启"
  - "V2 的 patch 工具把变更目标放在 input.patchText 的 Update/Delete File 指令里; 备份钩子必须解析 patchText, 不能假设所有文件工具都有 filePath"
---

# OpenCode V2 插件缓存与重复加载修复

## 现象

`edit-backup.js` 源码与 Home Manager 软链哈希一致, 但长驻 OpenCode V2 服务仍报
`Plugin must export a default definition ... Missing key at ["default"]`喵~

## 根因

服务进程在源码迁移前已运行很久; V2/Bun 按稳定模块路径缓存导出, 文件 watcher 重新加载同一路径时仍读到旧模块。`opencode service restart` 后,
全局插件恢复为 `edit-backup` ID 且启动日志没有新的加载错误喵~

同时, 插件既位于项目 `.opencode/plugins/`, 又经 Home Manager 软链进入全局插件目录; 在 `/etc/nixos` 项目里会加载两次喵~

用户实测还发现 `patch` 调用成功但没有生成快照。OpenCode 会话消息显示输入只有 `patchText`, 原实现虽将 `patch` 列入受支持工具, 却只从 `filePath/path/file` 取目标, 因而提前跳过备份喵~

## 修复

- 将源码移到 `home/Reiky-REI/tools/opencode-edit-backup.js`, 避开项目自动发现目录喵~
- Home Manager 只部署全局插件实例, 消除同项目双重注册喵~
- 新增用户级 `opencode-plugin-restart.path` 和 oneshot service: 监视源码文件/全局插件目录变化, 若 V2 `serve --service` 正在运行, 等原子写入结束后执行 `opencode service restart` 清掉模块缓存喵~
- switch 激活 Home Manager 链接时也会触发 watcher; HM oneshot 只启动独立 user transient unit 后立即退出, deferred unit 等 `nixos-rebuild-switch-to-configuration.service` 结束并缓冲 2 秒后重启 OpenCode, 避免 HM 激活与 switch 死锁、或中断 rebuild shell 喵~
- `targetPathsFor()` 为 `patch` 解析 `*** Update File:` / `*** Delete File:` 多文件路径, 为 `multiedit` 解析 edits 列表, 每个既存文件在工具执行前分别快照喵~
- 不主动重启空闲未启动的 OpenCode 服务喵~

## 验证

- 当前手动重启后, `opencode plugin list` 能识别全局 `edit-backup` ID喵~
- 用 fake tool context 调用 V2 `execute.before` 钩子并传入真实 patchText 格式, 确认旧内容 `before` 被复制到快照喵~
- 新 systemd path/service 与完整 NixOS toplevel 已 build 成功喵~
- patch 路径解析已修并重新 build; 应用此 generation 后需再用 OpenCode 原生 patch 做一次端到端验证喵~
- 旧日志里的历史 WARN 不会被自动删除喵~
