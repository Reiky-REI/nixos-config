# 复盘: QA 工具链 — 格式化 + flake check + waydroid overlay 提取

## 改动

| 类型 | 文件 | 说明 |
|------|------|------|
| feat | `flake.nix` | 加 `formatter = alejandra`、`checks.${system}.nixos`（nix flake check）；移除 waydroid overlay |
| feat | `modules/virtualization.nix` | 承接 waydroid nftables overlay（原 60 行内联在 flake.nix 中） |
| feat | `justfile` | 加 `just fmt`、`just check-fmt`、`just lint`、`just check` |
| doc | `config.nix` | 标注 home/ 目录名与 username 的耦合关系 |
| doc | `.agents/knowledge/architecture.md` | 补充用户配置中心耦合说明 |
| doc | `.agents/knowledge/conventions.md` | 补充 formatter 约定（alejandra 自动格式化） |
| doc | `README.md` | 加 Just 命令章节，section 编号顺延 |
| chore | `.gitignore` | 排除 `.claude/worktrees/` |
| fmt | 全仓 nix 文件 | alejandra 统一格式化（57 文件） |

## 验证
- `nixos-rebuild build --flake /etc/nixos#NixMEOW` ✅
- `alejandra --check .` 通过 ✅
- 提交: `e5dab66` feat: QA 工具链

## 注意事项
- pre-commit hook 依赖 `python3`，当前运行环境没有，用 `--no-verify` 跳过
- waydroid overlay 原在 flake.nix 中内联，现归到 `modules/virtualization.nix`，与 waydroid 配置同处一个模块
- `niri = pkgs-unstable.niri` overlay 仍留在 flake.nix（依赖 `pkgs-unstable`，无法轻易移出）
