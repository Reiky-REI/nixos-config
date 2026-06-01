{pkgs, ...}: {
  home.packages = with pkgs; [
    vlc
    splayer
  ];

  programs.mpv.enable = true;
  programs.obs-studio.enable = true;
}
