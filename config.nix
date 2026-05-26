# ===== 用户配置中心 =====
# 所有用户标识符统一在这里定义，其他地方通过 specialArgs 引用。
#
# 新增/删改用户时只需改这个文件，其他模块通过变量引用。
# 修改后执行 nixos-rebuild build --flake /etc/nixos#NixMEOW 验证。
{
  # 系统登录用户名（也是 home 目录名）
  username = "Reiky-REI";

  # 显示名称（用于 /etc/passwd 的 description 字段）
  fullName = "Reiky";

  # GitHub 用户名（用于 flake input URL）
  githubHandle = "Reiky-REI";
}
