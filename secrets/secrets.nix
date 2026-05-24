# ===== agenix 密钥配置 =====
# 此文件定义哪些 .age 文件可以被哪些 SSH 公钥解密。
#
# 日常操作:
#   编辑密钥:   agenix -e secrets/<name>.age -i ~/.ssh/id_ed25519
#   重加密:     agenix -r secrets/ -i ~/.ssh/id_ed25519
#   查看解密:   agenix -d secrets/<name>.age -i ~/.ssh/id_ed25519
#
# 解密产物: /run/agenix/<name> (rebuild 时自动生成)
# 加载方式: zsh 启动时自动 source /run/agenix/ai_api_key
#
# 当前可用公钥:
#   Reiky-REI@cook (主机的 SSH 公钥)

let
  user_name = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMY282QEpZWkXv8oTomNEKt0snDqDYitvBSpY7TdlH5c Reiky-REI@cook";
in {
  "ai_api_key.age".publicKeys = [user_name];
}

# 换电脑/重装系统后的操作:
# 1. 生成新 SSH 密钥:    ssh-keygen -t ed25519 -C "your@email"
# 2. 查看公钥:           cat ~/.ssh/id_ed25519.pub
# 3. 替换上面 user_name 的值
# 4. 重新加密:           agenix -r secrets/ -i ~/.ssh/id_ed25519
# 5. rebuild
