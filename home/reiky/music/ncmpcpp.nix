{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    mpc
  ];

  programs.ncmpcpp = {
    enable = true;
    mpdMusicDir = "${config.home.homeDirectory}/music";
    settings = {
      lyrics_directory = "${config.home.homeDirectory}/music";
      store_lyrics_in_song_dir = "yes";
    };
  };
}
