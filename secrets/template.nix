# ===== secrets.nix 模板 =====
# 用法 (本仓库已存在 secrets.nix, 此文件仅供换机/新仓库参考):
#   cp secrets/template.nix secrets/secrets.nix
#
# 命名约定: 小写 + 连字符
#   ai-api-key-<user>.age       每用户环境变量
#   <service>-credentials.age   服务凭据
#
# 重加密: agenix -r -i ~/.ssh/id_ed25519
let
  # 把下面的公钥替换成你自己的 SSH 公钥
  # 查看: cat ~/.ssh/id_ed25519.pub
  user_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... your@email";
in {
  "ai-api-key-<user>.age".publicKeys = [user_key];
}
# 多用户时，在 let 中添加更多公钥:
#   foo_key = "ssh-ed25519 BBB... foo@email";
#   bar_key = "ssh-ed25519 CCC... bar@email";
# 并在 in {} 中添加对应条目:
#   "ai-api-key-foo.age".publicKeys = [foo_key];
#   "ai-api-key-bar.age".publicKeys = [bar_key];

