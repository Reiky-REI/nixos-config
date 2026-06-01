---
date: 2026-06-01
module: secrets/ai_api_key_REIKY_REI.age
tags: [secrets, api-key, agnes-ai, environment-variables]
layer: common
severity: low
related:
  - ../../secrets/ai_api_key_REIKY_REI.age
  - ../retros/2026-05-27-xiaomi-api-key.md (相同模式)
experience:
  - "Agnes AI 使用 OpenAI 兼容 API，base URL 为 https://apihub.agnes-ai.com，model 为 agnes-2.0-flash"
  - "多个 API key 共存于同一个 ai_api_key_<USER>.age 文件中，通过不同环境变量名区分"
---

# 复盘：添加 Agnes AI API Key

## 变更内容
| 项目 | 值 |
|------|-----|
| API 服务 | Agnes AI (agnes-ai.com) |
| API Endpoint | `https://apihub.agnes-ai.com/v1/chat/completions` |
| Model | `agnes-2.0-flash` |
| 兼容性 | OpenAI Chat Completions API |
| 加密文件 | `secrets/ai_api_key_REIKY_REI.age` |

## 新增环境变量
- `AGNES_API_KEY_REIKY_REI` — Bearer Token 认证密钥
- `AGNES_API_BASE_URL` — API 基础地址

## 实施过程
1. 用 `agenix -d` 查看当前密钥内容
2. 用 `cat content | agenix -e` 方式更新加密文件（追加 2 行环境变量）
3. 用 `agenix -d` 验证解密结果
4. `nixos-rebuild build` 验证编译通过

## 说明
- 无需修改任何 Nix 模块代码，沿用现有 agenix 密钥管理模式
- zsh 启动时自动 source `/run/agenix/ai_api_key_REIKY_REI`，无需额外配置
- 与已有 `XIAOMI_API_KEY`、`DEEPSEEK_API_KEY_REIKY_REI` 等共存
- key 加密进 git，安全无虞
