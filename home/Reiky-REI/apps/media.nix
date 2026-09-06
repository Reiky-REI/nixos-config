{pkgs, ...}: {
  home.packages = with pkgs; [
    vlc
    splayer
    krita
    obs-studio
  ];

  programs.mpv.enable = true;
}
