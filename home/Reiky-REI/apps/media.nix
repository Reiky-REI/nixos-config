{pkgs, ...}: {
  home.packages = with pkgs; [
    vlc
    youtube-music
    spotify
    netease-cloud-music-gtk
  ];

  programs.mpv.enable = true;
  programs.obs-studio.enable = true;
}
