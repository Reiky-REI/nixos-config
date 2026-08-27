{pkgs, ...}: {
  home.packages = with pkgs; [
    vlc
    splayer
    krita
  ];

  programs.mpv.enable = true;
}
