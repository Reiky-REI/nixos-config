{pkgs, ...}: {
  home.packages = with pkgs; [
    # 上游已将 swww 更名为 awww(本机运行的守护进程即 awww-daemon)
    awww
  ];

  # 壁纸切换脚本: niri 快捷键 Mod+Shift+W 调用 ~/.config/wallpaper/script/swww-rofi.sh
  # 原先由已废弃的 desktop/hyprland/scripts 部署(整目录已随 hyprland 清理移除),
  # 现迁到本模块由 nix 托管, 避免依赖历史残留文件
  home.file.".config/wallpaper/script/swww-rofi.sh" = {
    source = ./swww-rofi.sh;
    executable = true;
    # 该路径此前是 hyprland 时代的历史残留真实文件(非 nix 托管),
    # 不 force 会触发 home-manager clobber 报错导致 activation 失败
    force = true;
  };

  # 壁纸文件已迁移到 ~/Pictures/Wallpapers/
  # 由用户直接管理，不再通过 nix 部署
}
