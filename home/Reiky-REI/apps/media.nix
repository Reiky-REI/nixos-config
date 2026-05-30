{pkgs, ...}: {
  home.packages = with pkgs; [
    vlc
    youtube-music
    spotify
    splayer
  ];

  programs.mpv.enable = true;
  programs.obs-studio.enable = true;
}
