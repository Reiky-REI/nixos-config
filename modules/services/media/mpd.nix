{config, lib, username, ...}: {
  services.mpd.enable = lib.mkIf (config.meow.enabled ? "media-mpd") true;
  services.mpd = {
    # 26.05 起用声明式 settings (RFC42), 替代废弃的 extraConfig
    settings = {
      music_directory = "/home/${username}/music";
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
