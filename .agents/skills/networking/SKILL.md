---
name: networking
description: 代理/GitHub token/镜像源/SSH 配置
---

## 代理设置
- 地址: `http://127.0.0.1:7897`
- 设置方式: `export http_proxy=http://127.0.0.1:7897`
- 自动加载: `.agents/config/env.sh`

## GitHub token
- 文件: `.agents/config/token`（gitignore 保护）
- 用途: Nix 构建时访问 GitHub
- 自动加载: `env.sh` 会读取此文件

## 镜像源
| 名称 | URL |
|------|-----|
| TUNA | `https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store` |
| USTC | `https://mirrors.ustc.edu.cn/nix-channels/store` |
| cache.nixos.org | `https://cache.nixos.org` |

配置位置: `flake.nix` 的 `nixConfig.substituters`

## env.sh（代理+token 自动加载）
```bash
source .agents/config/env.sh
```
在 rebuild.sh 中已自动 source，一般不需要手动执行。
