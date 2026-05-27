---
date: 2026-05-27
module: secrets/ai_api_key_REIKY_REI.age
tags: [secrets, api-key, xiaomi, environment-variables]
related:
  - ../secrets.md (密钥管理手册)
  - ../known-issues.md (密钥相关故障排查)
---

# 复盘: 添加小米 API key 到用户密钥文件

## 改动

| 操作 | 文件 | 说明 |
|------|------|------|
| 修改 | `secrets/ai_api_key_REIKY_REI.age` | 添加 XIAOMI_API_KEY 和 XIAOMI_API_ENDPOINT 环境变量 |

## 环境变量

添加的两个环境变量：
- `XIAOMI_API_KEY`: 小米 API 密钥，用于 AI 模型调用
- `XIAOMI_API_ENDPOINT`: 小米 API 端点 URL (`https://api.xiaomimimo.com/`)

## 验证
- `nixos-rebuild build --flake /etc/nixos#NixMEOW` ✅ 构建通过
- 环境变量在 shell 启动时自动加载（通过 `/run/agenix/ai_api_key_Reiky-REI`）

## 注意事项
- 密钥文件仅对用户 Reiky-REI 可用，通过 `age.secrets.ai_api_key_REIKY_REI.owner = user.username` 控制
- 环境变量在 zsh 启动时自动加载，无需修改 zsh.nix
- 密钥已加密存储，只有当前用户可访问
- 如需为其他用户添加相同密钥，需要创建新的 `.age` 文件并修改 `secrets.nix`
