# 复盘: Git stash 完全整理

## 改动

| 操作 | 说明 |
|------|------|
| 路径修复 | AGENTS.md / INDEX.md / conventions.md / known-issues.md — `retros/` → `knowledge/retros/`，补丁路径修正 |
| 模块目录化 | `modules/default.nix` 导入 `./virtualization.nix` → `./virtualization`，`./documentation.nix` → `./documentation` |
| 合并 overlay | 将 `modules/virtualization.nix` 中的 waydroid nftables overlay 合并到 `modules/virtualization/default.nix`（目录版原缺此 overlay） |
| 清理重复文件 | 删除 `modules/virtualization.nix`、`modules/documentation.nix`、`patches/btmtk-wmt-fix.patch`、根 `hardware-configuration.nix`（均已有目录版或 relocated 版） |
| hardware 引用修正 | `hosts/MEOW/hardware.nix` 导入 `../../hardware-configuration.nix` → `./hardware-configuration.nix` |
| 复盘迁移 | 根 `retros/` → `.agents/knowledge/retros/`（含遗漏的 tailscale.md），更新 `.retros-index.md` 为完整 21 篇列表 |
| rebuild.sh 增强 | 添加 `--print-build-logs` verbose 模式、镜像源 substituters、access-tokens 参数（来自 stash@{3}） |
| 清理 stash | 全部 4 个 stash 已 review 并 drop |

## 验证

- `nixos-rebuild build --flake /etc/nixos#NixMEOW` ✅
