{username, ...}: {
  services.mpd.enable = true;
  services.mpd = {
    musicDirectory = "/home/${username}/music";
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
