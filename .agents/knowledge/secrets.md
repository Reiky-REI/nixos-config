# Secrets 密钥管理手册

> 使用 agenix 管理加密密钥，自动解密并注入系统。

## 原理

```
secrets/ai-api-key-<user>.age (age 加密，可安全进 git)
  ↓ rebuild 时 agenix 用 SSH 私钥解密
/run/agenix/ai-api-key-<user> (明文)
  ↓ zsh 启动时 source /run/agenix/ai-api-key-*
shell 环境变量 (DEEPSEEK_API_KEY_<USER>, NIX_ACCESS_TOKEN 等)
```

## 命名规则（2026-10-01 起统一为「小写 + 连字符」）

| 类型 | 文件 | 运行时路径 | 例子 |
|------|------|-----------|------|
| 每用户环境变量 | `ai-api-key-<user>.age` | `/run/agenix/ai-api-key-<user>` | `ai-api-key-reiky.age` |
| 服务凭据 | `<service>-credentials.age` | `/run/agenix/<service>-credentials` | `nas-smb-credentials.age` |
| 模板 | `ai-api-key.age.template` / `template.nix` | — | — |

- agenix 的 `age.secrets.<键>` 的**键名**就是 `/run/agenix/` 下的文件名（`modules/age.nix` 的 `name` 选项，普通字符串），**允许连字符**，没有 `[a-zA-Z0-9_-]` 这种限制喵~（旧文档里"连字符要换下划线"的说法已作废）。
- 密钥内容里的环境变量名不受文件名约束，以消费方配置引用的名字为准（如 `DEEPSEEK_API_KEY_REIKY_REI`）。

## 工作目录

```bash
cd /etc/nixos/secrets
# （所有 agenix 命令都从这里执行，因为当前目录需要 secrets.nix）
```

## 日常操作

### 编辑当前用户的密钥
```bash
cd /etc/nixos/secrets
agenix -e ai-api-key-reiky.age -i ~/.ssh/id_ed25519
```

### 查看当前密钥（不解密文件）
```bash
cat /run/agenix/ai-api-key-reiky
```

### 查看加密文件内容
```bash
agenix -d ai-api-key-reiky.age -i ~/.ssh/id_ed25519
```

### 重加密所有密钥
换了 SSH 密钥或改了 secrets.nix 后：
```bash
agenix -r -i ~/.ssh/id_ed25519
```

### 轮换 GitHub token（NIX_ACCESS_TOKEN）
```bash
bash .agents/config/rotate-nix-token.sh
```
它只替换密钥里的 `NIX_ACCESS_TOKEN` 一行，其余 API key 原样保留，并同步回退文件 `.agents/config/token`。

## 新增一个用户（例如 "foo"）

```bash
# 1. 让 foo 提供 SSH 公钥: cat ~/.ssh/id_ed25519.pub

# 2. secrets/secrets.nix 加入公钥与文件条目:
#      "ai-api-key-foo.age".publicKeys = [foo_key];

# 3. 创建加密文件:
cp ai-api-key.age.template ai-api-key-foo.age
agenix -e ai-api-key-foo.age -i ~/.ssh/id_ed25519   # 粘贴 export ... 内容

# 4. lib/mk-host.nix 增加条目:
#      age.secrets."ai-api-key-foo" = {
#        file = ../secrets/ai-api-key-foo.age;
#        owner = "foo";
#      };

# 5. rebuild，foo 的 zsh 会通过 /run/agenix/ai-api-key-* 自动加载
```

## 系统集成说明

### 定义位置（lib/mk-host.nix）

```nix
# users.nix 中定义身份: reiky = { username = "Reiky-REI"; ... };
# mk-host.nix 里由 users.nix 与 machines.nix 解析 primaryUser
age.secrets."ai-api-key-reiky" = {
  file = ../secrets/ai-api-key-reiky.age;
  owner = primaryUser.username;
};
age.identityPaths = [ "${primaryUser.homeDirectory}/.ssh/id_ed25519" ];
```

### zsh 中的自动加载（home/Reiky-REI/shell/zsh.nix）

```nix
for file in /run/agenix/ai-api-key-*; do
  [ -f "$file" ] && source "$file"
done
```

### 构建环境（.agents/config/env.sh）

```bash
if [ -f /run/agenix/ai-api-key-reiky ]; then
  source /run/agenix/ai-api-key-reiky
fi
# 回退: .agents/config/token（agenix 不可用时）
```

## 当前密钥清单

| 文件 | 运行时路径 | 用途 / 环境变量 |
|------|-----------|-----------------|
| `ai-api-key-reiky.age` | `/run/agenix/ai-api-key-reiky` | `DEEPSEEK_API_KEY_REIKY_REI`, `NIX_ACCESS_TOKEN`, `XIAOMI_API_KEY`, `XIAOMI_API_ENDPOINT` |
| `nas-smb-credentials.age` | `/run/agenix/nas-smb-credentials` | NAS SMB 挂载凭据 (root only) |

## 故障排查

| 症状 | 原因 | 解决 |
|------|------|------|
| `no identity matched` | 私钥不在 agent 或与 secrets.nix 不匹配 | `ssh-add ~/.ssh/id_ed25519` |
| `permission denied: /run/agenix/...` | 文件 root 所有 | 设 `age.secrets.<name>.owner = "你的用户名"` |
| `/run/agenix/` 为空 | rebuild 未运行 | 重新 `nixos-rebuild switch` |
| `agenix -e` 报 attribute missing | secrets.nix 无对应条目 | 在 secrets.nix 中添加文件条目 |
| 改名后 `/run/agenix/` 还是旧名 | 未 switch | `sudo nixos-rebuild switch`（旧名文件随新代消失） |
