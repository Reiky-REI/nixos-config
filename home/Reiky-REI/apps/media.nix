{pkgs, ...}: {
  home.packages = with pkgs; [
    vlc
    splayer
  ];

  programs.mpv.enable = true;
}
