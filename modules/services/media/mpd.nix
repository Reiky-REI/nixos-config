{username, ...}: {
  services.mpd.enable = true;
  services.mpd = {
    musicDirectory = "/home/${username}/music";
    # 26.05 起用声明式 settings (RFC42), 替代废弃的 extraConfig
    settings = {
      restore_paused = "yes";
      auto_update = "yes";
      audio_output = [
        {
          type = "pipewire";
          name = "PipeWire Output";
        }
      ];
    };
  };
}
