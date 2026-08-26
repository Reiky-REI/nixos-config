{pkgs, ...}: {
  home.packages = with pkgs; [
    # 上游已将 swww 更名为 awww(本机运行的守护进程即 awww-daemon)
    awww
  ];
  # 壁纸文件已迁移到 ~/Pictures/Wallpapers/
  # 由用户直接管理，不再通过 nix 部署
}
