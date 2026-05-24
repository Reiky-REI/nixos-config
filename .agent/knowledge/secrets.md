# Secrets 密钥管理手册

> 使用 agenix 管理加密密钥，自动解密并注入系统。

## 原理

```
secrets/<name>.age (age 加密，可安全进 git)
  ↓ rebuild 时 agenix 用 SSH 私钥解密
/run/agenix/<name> (明文，仅 root 可读)
  ↓ zsh 启动时 source
shell 环境变量 (DEEPSEEK_API_KEY, NIX_ACCESS_TOKEN 等)
```

## 工作目录

所有命令在仓库根目录 `/etc/nixos` 执行，或 cd 到 `secrets/`。

## 日常操作

### 编辑已有密钥
```bash
cd /etc/nixos
agenix -e secrets/ai_api_key.age -i ~/.ssh/id_ed25519 --secrets-dir ./secrets
```

文件格式是 shell exports，例如：
```bash
export DEEPSEEK_API_KEY="sk-..."
export NIX_ACCESS_TOKEN="ghp_..."
```

### 新增一个密钥
```bash
cd /etc/nixos/secrets

# 1. 在 secrets.nix 中添加条目
#    "my_key.age".publicKeys = [user_name];

# 2. 创建加密文件
echo 'export MY_SECRET="value"' > /tmp/my_plain
agenix -e my_key.age -i ~/.ssh/id_ed25519
# 编辑器打开后把 /tmp/my_plain 的内容粘贴进去，保存

# 3. 在需要使用的地方 source (例如 zsh.nix)
#    for file in /run/agenix/my_key; do
#      [ -f "$file" ] && source "$file"
#    done
```

### 重加密所有密钥
换 SSH 密钥后必须重加密：
```bash
agenix -r secrets/ -i ~/.ssh/id_ed25519 --secrets-dir ./secrets
```

### 查看解密内容（不编辑）
```bash
agenix -d secrets/ai_api_key.age -i ~/.ssh/id_ed25519 --secrets-dir ./secrets
```

## 换电脑 / 重装系统

1. 生成新 SSH 密钥：
   ```bash
   ssh-keygen -t ed25519 -C "your@email"
   ```

2. 查看公钥：
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```

3. 编辑 `secrets/secrets.nix`，将 `user_name` 替换为新公钥

4. 将私钥内容发给旧电脑（或用旧私钥解密原有文件重新加密）

5. Run `agenix -r secrets/ -i ~/.ssh/id_ed25519 --secrets-dir ./secrets`

6. Rebuild

## 当前密钥清单

| 文件 | 用途 | 解密路径 | 加载位置 |
|------|------|----------|----------|
| `ai_api_key.age` | AI API Key + GitHub Token | `/run/agenix/ai_api_key` | zsh initContent |

## 故障排查

| 症状 | 原因 | 解决 |
|------|------|------|
| `no identity matched` | 私钥不在 agent 或与 secrets.nix 不匹配 | `ssh-add ~/.ssh/id_ed25519` 或更新 secrets.nix |
| `/run/agenix/` 为空 | rebuild 未运行或 agenix 模块未启用 | 重新 `nixos-rebuild switch` |
| `agenix -e` 找不到 secrets.nix | 不在正确目录 | `--secrets-dir ./secrets` 或 cd 到 secrets/ |
