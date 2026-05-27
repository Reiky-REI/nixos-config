---
name: secrets
description: agenix 密钥管理操作 — 编辑/新增/查看/重加密
agents: [opencode, claude]
---
> 完整文档见 knowledge/secrets.md

## 工作目录
```bash
cd /etc/nixos/secrets
```

## 编辑当前用户的密钥
```bash
cd /etc/nixos/secrets
agenix -e ai_api_key_REIKY_REI.age -i ~/.ssh/id_ed25519
```

文件中变量名包含用户名：
```bash
export DEEPSEEK_API_KEY_REIKY_REI="sk-..."
export NIX_ACCESS_TOKEN="ghp_..."
```

## 查看当前密钥（不解密文件）
```bash
cat /run/agenix/ai_api_key_REIKY_REI
```

## 查看加密文件内容
```bash
agenix -d ai_api_key_REIKY_REI.age -i ~/.ssh/id_ed25519
```

## 重加密所有密钥
换了 SSH 密钥或改了 secrets.nix 后：
```bash
agenix -r -i ~/.ssh/id_ed25519
```

## 新增用户流程
1. 让用户提供 SSH 公钥
2. 编辑 `secrets/secrets.nix` 添加公钥和文件条目
3. 创建加密文件: `cat /tmp/plain | agenix -e ai_api_key_foo.age -i ~/.ssh/id_ed25519`
4. 在 `flake.nix` 的 `age.secrets` 中添加条目
5. rebuild

## 故障排查
| 症状 | 原因 | 解决 |
|------|------|------|
| `no identity matched` | 私钥不在 agent | `ssh-add ~/.ssh/id_ed25519` |
| `permission denied` | 文件 root 所有 | 设 `age.secrets.<name>.owner = "用户名"` |
| `/run/agenix/` 为空 | rebuild 未运行 | 重新 `nixos-rebuild switch` |
