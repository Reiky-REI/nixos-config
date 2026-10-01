# ===== agenix 密钥配置 =====
# 此文件定义哪些 .age 文件可以被哪些 SSH 公钥解密。
#
# 命名约定 (2026-10-01 起): 小写 + 连字符
#   ai-api-key-<user>.age        每用户的 API key / 环境变量文件
#   <service>-credentials.age    服务凭据
#   模板: template.nix / ai-api-key.age.template
#
# 日常操作 (都在 secrets/ 目录执行, 当前目录需要 secrets.nix):
#   编辑密钥:   agenix -e <name>.age -i ~/.ssh/id_ed25519
#   重加密:     agenix -r -i ~/.ssh/id_ed25519
#   查看解密:   agenix -d <name>.age -i ~/.ssh/id_ed25519
#
# 解密产物: /run/agenix/<age.secrets 键名> (rebuild 时自动生成)
#   agenix 的键名即运行时文件名, 允许连字符 (无字符集限制), 见 modules/age.nix
# 加载方式: zsh 启动时自动 source /run/agenix/ai-api-key-*
#
# 当前可用的 SSH 公钥
let
  reiky_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMY282QEpZWkXv8oTomNEKt0snDqDYitvBSpY7TdlH5c Reiky-REI@cook";
in {
  # 新加用户时:
  #   1. 把用户的 SSH 公钥加到上方
  #   2. 添加一行: "ai-api-key-<user>.age".publicKeys = [<key_name>];
  #   3. 创建加密文件: cp ai-api-key.age.template ai-api-key-<user>.age 后 agenix -e 编辑
  #   4. lib/mk-host.nix 增加 age.secrets."ai-api-key-<user>" = { file = ...; owner = ...; };
  "ai-api-key-reiky.age".publicKeys = [reiky_key];
  "nas-smb-credentials.age".publicKeys = [reiky_key];
}
# 换电脑/重装系统后的操作:
# 1. 生成新 SSH 密钥:    ssh-keygen -t ed25519 -C "your@email"
# 2. 查看公钥:           cat ~/.ssh/id_ed25519.pub
# 3. 替换上方对应的公钥值
# 4. 重新加密:           agenix -r -i ~/.ssh/id_ed25519
# 5. rebuild

