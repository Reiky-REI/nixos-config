{pkgs, ...}: {
  # dsh (DeepSeek Harness) CLI — 由 Reiky-nixpkgs 私源提供, 替代此前
  # 家目录下的 `npm install @deepseek-ai/dsh` 非声明式安装。
  # web 服务仍由 systemd 服务 dsh-fence 托管(见 modules/services/dsh-fence.nix),
  # 手动执行 dsh web 会与其抢占 3080 端口。
  home.packages = [pkgs.dsh];
}
