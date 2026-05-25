{pkgs, ...}: {
  home.packages = with pkgs; [
    vlc
    youtube-music
    spotify
    splayer
    bilibili
  ];

  programs.mpv.enable = true;
  programs.obs-studio.enable = true;
}
