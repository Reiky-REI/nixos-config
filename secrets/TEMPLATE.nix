# ===== secrets.nix 模板 =====
# 复制此文件并重命名为 secrets.nix:
#   cp secrets/TEMPLATE.nix secrets/secrets.nix
#
# 然后运行:
#   agenix -r secrets/ -i ~/.ssh/id_ed25519

let
  # 把下面的公钥替换成你自己的 SSH 公钥
  # 查看: cat ~/.ssh/id_ed25519.pub
  user_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... your@email";
in {
  "ai_api_key_<用户名>.age".publicKeys = [user_key];
}

# 多用户时，在 let 中添加更多公钥:
#   foo_key = "ssh-ed25519 BBB... foo@email";
#   bar_key = "ssh-ed25519 CCC... bar@email";
# 并在 in {} 中添加对应条目:
#   "ai_api_key_foo.age".publicKeys = [foo_key];
#   "ai_api_key_bar.age".publicKeys = [bar_key];
