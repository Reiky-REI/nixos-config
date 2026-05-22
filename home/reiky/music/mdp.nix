{pkgs, ...}: {
  home.packages = with pkgs; [
    mpc
  ];
  services.mpd.enable = true;
  services.mpd = {
    musicDirectory = "/home/reiky/music";
    extraConfig = ''
      audio_output {
        type "pipewire"
        name "PipeWire Output"
      }

      restore_paused "yes"
      auto_update "yes"
    '';
  };
  programs.ncmpcpp = {
    enable = true;
    mpdMusicDir = "/home/reiky/music";
    settings = {
      lyrics_directory = "/home/reiky/music";
      store_lyrics_in_song_dir = "yes";
    };
  };
}
