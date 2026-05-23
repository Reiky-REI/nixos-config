{ ... }: {
  services.mpd.enable = true;
  services.mpd = {
    musicDirectory = "/home/Reiky-REI/music";
    extraConfig = ''
      audio_output {
        type "pipewire"
        name "PipeWire Output"
      }
      restore_paused "yes"
      auto_update "yes"
    '';
  };
}
