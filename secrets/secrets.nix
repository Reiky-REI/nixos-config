# ===== agenix 密钥配置 =====
# 此文件定义哪些 .age 文件可以被哪些 SSH 公钥解密。
#
# 日常操作:
#   编辑密钥:   agenix -e secrets/<name>.age -i ~/.ssh/id_ed25519
#   重加密:     agenix -r secrets/ -i ~/.ssh/id_ed25519
#   查看解密:   agenix -d secrets/<name>.age -i ~/.ssh/id_ed25519
#
# 解密产物: /run/agenix/<name> (rebuild 时自动生成)
# 加载方式: zsh 启动时自动 source (按用户名匹配)

# 当前可用的 SSH 公钥
let
  reiky_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMY282QEpZWkXv8oTomNEKt0snDqDYitvBSpY7TdlH5c Reiky-REI@cook";
in {

  # 每个用户的密钥文件，命名格式: ai_api_key_<USERNAME>.age
  # 新加用户时:
  #   1. 把用户的 SSH 公钥加到上方
  #   2. 添加一行: "ai_api_key_<USERNAME>.age".publicKeys = [<key_name>];
  #   3. 创建加密文件: agenix -e secrets/ai_api_key_<USERNAME>.age
  "ai_api_key_REIKY_REI.age".publicKeys = [reiky_key];
}

# 换电脑/重装系统后的操作:
# 1. 生成新 SSH 密钥:    ssh-keygen -t ed25519 -C "your@email"
# 2. 查看公钥:           cat ~/.ssh/id_ed25519.pub
# 3. 替换上方对应的公钥值
# 4. 重新加密:           agenix -r secrets/ -i ~/.ssh/id_ed25519
# 5. rebuild
