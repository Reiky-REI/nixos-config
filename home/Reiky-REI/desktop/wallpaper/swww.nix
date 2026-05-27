{pkgs, ...}: {
  home.packages = with pkgs; [
    swww
  ];
  # 壁纸文件已迁移到 ~/Pictures/Wallpapers/
  # 由用户直接管理，不再通过 nix 部署
}
