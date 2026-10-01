# artifacts — 归档区

收纳 `/etc/nixos` 根目录与工作区散落的一次性脚本、日志与配置片段（与 home `~/.agents/artifacts/` 同构）。

## 约定

- 按用途放子目录：`scripts/`、`logs/`、`media/`、`plans/`、`config-snippets/`
- 文件名小写 + 连字符；归档时在文件头部写「归档说明」（来源 / 背景 / 状态）
- 只归档有价值的历史产物；纯缓存与构建产物直接删除，并按铁律留删除清单（`~/.local/state/delete-manifests/`）

## 当前内容

| 文件 | 来源 | 说明 |
|------|------|------|
| `scripts/decode-objects.py` | 仓库根 `decode_objects.py`（曾被 gitignore） | 2026-08-2x git 对象修复的一次性解码脚本，见复盘 `retros/2026-09-01-git-corrupt-history-repair.md` |
| `scripts/disk-cleanup.sh` | 仓库根 `cleanup.sh`（曾被 gitignore） | 早期手动磁盘清理脚本，现由 skill: disk-cleanup 流程取代 |
