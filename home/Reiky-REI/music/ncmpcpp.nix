{pkgs, ...}: {
  home.packages = with pkgs; [
    mpc
  ];

  programs.ncmpcpp = {
    enable = true;
    mpdMusicDir = "/home/Reiky-REI/music";
    settings = {
      lyrics_directory = "/home/Reiky-REI/music";
      store_lyrics_in_song_dir = "yes";
    };
  };
}
