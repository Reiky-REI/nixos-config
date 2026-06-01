{pkgs, ...}: {
  home.packages = with pkgs; [
    vlc
  ];

  programs.mpv.enable = true;
  programs.obs-studio.enable = true;
}
