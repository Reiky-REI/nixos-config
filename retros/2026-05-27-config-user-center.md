# 2026-05-27: config.nix 用户配置中心

## 目标
将所有硬编码的 `Reiky-REI` 用户名提取为变量，在 `config.nix` 统一管理。

## 改动

### 新增
- `config.nix` — 用户配置中心，定义 `username`/`fullName`/`githubHandle`

### 修改

| 文件 | 改动 |
|------|------|
| `flake.nix` | import `config.nix`，通过 `specialArgs`/`extraSpecialArgs` 传递 `username`、`fullName` |
| `hosts/MEOW/default.nix` | `users.users.Reiky-REI` → `users.users.${username}` |
| `modules/common/default.nix` | `trusted-users` 中硬编码 → `username` 变量 |
| `modules/services/media/mpd.nix` | 硬编码路径 → `/home/${username}/music` |
| `home/Reiky-REI/music/ncmpcpp.nix` | 硬编码路径 → `config.home.homeDirectory` 变量 |

### 文档更新
- `README.md` — 目录树和示例中的 `Reiky-REI` → `{username}` 占位符
- `.agents/knowledge/architecture.md` — 文件树标注 `config.nix`，新增"用户配置中心"节
- `.agents/knowledge/conventions.md` — 新增"用户标识集中管理"节
- `.agents/knowledge/secrets.md` — 更新 agenix 配置示例，显示变量引用方式

## 变量传递路径
```
config.nix (定义 username/fullName)
  → flake.nix let (import)
    → specialArgs → NixOS 模块
    → extraSpecialArgs → home-manager 模块
```

## 新增用户的步骤
未来新增用户只需：
1. 改 `config.nix` 中的定义
2. `secrets/secrets.nix` 添加公钥
3. 创建对应的 `.age` 加密文件
4. rebuild
