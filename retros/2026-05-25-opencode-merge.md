# 复盘: NixOpencodeMEOW 合并入主配置

## 目标
将 opencode 从外部 `~/WorkSpace/NixOpencodeMEOW` devShell 合并到 `/etc/nixos`，确保每次重建系统时 opencode 二进制自动可用。

## 操作

| 操作 | 文件 | 说明 |
|------|------|------|
| development 子目录化 | `modules/development/{wine,opencode}/default.nix` | 原 default.nix 改为纯入口 |
| opencode 全局安装 | `modules/development/opencode/default.nix` | `pkgs-unstable.opencode` 进 `environment.systemPackages` |
| opencode.json 合并 | `opencode.json` | 加入 model/provider/permission/skills 配置 |
| skill 迁移 | `.agents/skills/nixos-manager/SKILL.md` | 从 NixOpencodeMEOW 复制 |
| LSP 配置 | `hosts/MEOW/opencode.json` | nixd 路径改为 `/etc/nixos` |

## 验证
- `nixos-rebuild build --flake /etc/nixos#NixMEOW` ✅ 通过
- 产物: `/nix/store/jpxvq9415bdsfmihfcbhhz1hhnvcyzc2-nixos-system-NixMEOW-25.11.20260518.687f05a`
- opencode 1.15.5 已纳入系统路径

## 后续
- NixOpencodeMEOW 项目可归档或保留为独立 dev shell（不再依赖）
- `nixos-rebuild switch` 后验证 `which opencode` 应返回系统路径
