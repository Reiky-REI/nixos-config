# ===== 机器注册中心 =====
# 添加新机器时，在这里注册主机名和算力档位。
# 档位确定哪些性能特性开启（blur、shadow、动画等）。
#
# 使用方式：
# 1. 新机器上用 nixos-generate-config 生成硬件配置
# 2. 在此注册 { hostname = { profile = "..."; }; }
# 3. 创建 hosts/{hostname}/default.nix + hardware-configuration.nix
# 4. 在 flake.nix 中添加 nixosConfigurations 条目
# 5. 构建：nixos-rebuild build --flake /etc/nixos#{hostname}
#
# 注意：未在此注册的 hostname 会导致 build 直接报错（abort），
# 这是故意的——防止意外在未适配的机器上部署。
{
  "NixMEOW" = {
    profile = "high";
    note = "主力机 — RTX 4070 + AMD 核显";
  };

  # 示例：低算力笔记本
  # "NixPentium" = {
  #   profile = "low";
  #   note = "老奔腾笔记本，无独显";
  # };
}
