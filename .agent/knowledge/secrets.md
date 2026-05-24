# Secrets 密钥管理手册

> 使用 agenix 管理加密密钥，自动解密并注入系统。

## 原理

```
secrets/ai_api_key_<USER>.age (age 加密，可安全进 git)
  ↓ rebuild 时 agenix 用 SSH 私钥解密
/run/agenix/ai_api_key_<USER> (明文)
  ↓ zsh 按 ${USER} 自动 source
shell 环境变量 (DEEPSEEK_API_KEY_<USER>, NIX_ACCESS_TOKEN 等)
```

## 命名规则

每个用户的密钥文件命名格式：`ai_api_key_<用户名>.age`

- **Reiky-REI** → `ai_api_key_REIKY_REI.age` → 环境变量 `DEEPSEEK_API_KEY_REIKY_REI`
- 新用户 `foo` → `ai_api_key_foo.age` → 环境变量 `DEEPSEEK_API_KEY_foo`

## 工作目录

```bash
cd /etc/nixos/secrets
# （所有 agenix 命令都从这里执行，因为当前目录需要 secrets.nix）
```

## 日常操作

### 编辑当前用户的密钥
```bash
cd /etc/nixos/secrets
agenix -e ai_api_key_REIKY_REI.age -i ~/.ssh/id_ed25519
```

文件中变量名要包含你的用户名：
```bash
export DEEPSEEK_API_KEY_REIKY_REI="sk-..."
export NIX_ACCESS_TOKEN="ghp_..."
```

### 新增一个用户（例如：添加用户 "foo"）

步骤如下：

```bash
# 1. 让 foo 提供他的 SSH 公钥
#    cat ~/.ssh/id_ed25519.pub

# 2. 编辑 secrets/secrets.nix，把 foo 的公钥加进去
#    let
#      reiky_key = "ssh-ed25519 AAA...";
#      foo_key   = "ssh-ed25519 BBB...";
#    in {
#      "ai_api_key_REIKY_REI.age".publicKeys = [reiky_key];
#      "ai_api_key_foo.age".publicKeys       = [foo_key];
#    }

# 3. 把 foo 的密钥内容写到临时文件
echo 'export DEEPSEEK_API_KEY_foo="sk-..."
export NIX_ACCESS_TOKEN_foo="ghp_..."' > /tmp/foo_plain

# 4. 创建加密文件（编辑器打开后粘贴 /tmp/foo_plain 内容）
cat /tmp/foo_plain | agenix -e ai_api_key_foo.age -i ~/.ssh/id_ed25519

# 5. 在 flake.nix 的 age.secrets 中添加 foo 的条目
#    age.secrets.ai_api_key_foo = {
#      file = ./secrets/ai_api_key_foo.age;
#      owner = "foo";
#    };

# 6. rebuild，foo 的 zsh 会在启动时自动读取 /run/agenix/ai_api_key_foo
```

### 查看当前用户的密钥（不解密文件）
```bash
cat /run/agenix/ai_api_key_REIKY_REI
```

### 查看加密文件内容
```bash
agenix -d ai_api_key_REIKY_REI.age -i ~/.ssh/id_ed25519
```

### 重加密所有密钥
换了 SSH 密钥或改了 secrets.nix 后：
```bash
agenix -r -i ~/.ssh/id_ed25519
```

## 系统集成说明

### flake.nix 中的配置
```nix
age.secrets.ai_api_key_REIKY_REI = {
  file = ./secrets/ai_api_key_REIKY_REI.age;  # 源文件
  owner = "Reiky-REI";                         # 解密后文件所有者
};
age.identityPaths = [ "/home/Reiky-REI/.ssh/id_ed25519" ];
```

### zsh 中的自动加载
```nix
# home/Reiky-REI/shell/zsh.nix
for file in /run/agenix/ai_api_key_${USER}; do
  [ -f "$file" ] && source "$file"
done
```

### age.secrets 名限制
age.secrets 键名只能包含 `[a-zA-Z0-9_-]`，所以用户名中的连字符需要替换为下划线：
- 用户 `Reiky-REI` → age.secrets 键为 `ai_api_key_REIKY_REI`
- 但 `/run/agenix/` 中文件名可以带连字符（由 age file 名决定）

## 当前密钥清单

| 文件 | 用户 | 解密路径 | 环境变量 |
|------|------|----------|----------|
| `ai_api_key_REIKY_REI.age` | Reiky-REI | `/run/agenix/ai_api_key_REIKY_REI` | `DEEPSEEK_API_KEY_REIKY_REI`, `NIX_ACCESS_TOKEN` |

## 故障排查

| 症状 | 原因 | 解决 |
|------|------|------|
| `no identity matched` | 私钥不在 agent 或与 secrets.nix 不匹配 | `ssh-add ~/.ssh/id_ed25519` |
| `permission denied: /run/agenix/...` | 文件 root 所有 | 设 `age.secrets.<name>.owner = "你的用户名"` |
| `/run/agenix/` 为空 | rebuild 未运行 | 重新 `nixos-rebuild switch` |
| `agenix -e` 报 attribute missing | secrets.nix 无对应条目 | 在 secrets.nix 中添加文件条目 |
