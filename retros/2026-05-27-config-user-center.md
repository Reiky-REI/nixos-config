# 复盘: config.nix 用户配置中心

## 改动

| 操作 | 文件 | 说明 |
|------|------|------|
| 新增 | `config.nix` | 用户配置中心，定义 `username`/`fullName`/`githubHandle` |
| 重构 | `flake.nix` | import config.nix，通过 specialArgs/extraSpecialArgs 传递 username/fullName |
| 重构 | `hosts/MEOW/default.nix` | `users.users.Reiky-REI` → `users.users.${username}` |
| 重构 | `modules/common/default.nix` | `trusted-users` 中硬编码 → `username` 变量 |
| 重构 | `modules/services/media/mpd.nix` | `/home/Reiky-REI/music` → `/home/${username}/music` |
| 重构 | `home/Reiky-REI/music/ncmpcpp.nix` | 硬编码路径 → `${config.home.homeDirectory}/music` |
| 文档 | `README.md` | 目录树加 config.nix，路径用 `{username}` 占位符 |
| 文档 | `.agents/knowledge/{architecture,conventions,secrets}.md` | 标注 config.nix 角色和引用方式 |

## 验证
- `nixos-rebuild build --flake /etc/nixos#NixMEOW` ✅ 构建通过
- 提交: `b4868ea` feat: config.nix 用户配置中心

## 注意事项
- `secrets.nix` 由 agenix 独立求值，无法引用 config.nix，保持 `reiky_key` 变量形式不变
- `/run/agenix/` 中的文件名和 `.age` 加密文件名与变量无关，仍用原命名
- `config.nix` 新文件需先 `git add` 才能 flake eval（已知限制）
- `home/Reiky-REI/` 目录名本身不变，只改 nix 文件中的引用方式
