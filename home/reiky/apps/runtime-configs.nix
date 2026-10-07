{
  config,
  lib,
  pkgs,
  ...
}: let
  mergeJson = import ../lib/merge-json-activation.nix {inherit lib pkgs;};
  youtubeMusicSettings = pkgs.writeText "youtube-music-settings.json" (builtins.readFile ./youtube-music-settings.json);
in {
  home.file.".config/pigma/config.toml".source = ./pigma.toml;

  # SPlayer 已于 2026-10-07 卸载, mergeSPlayerSettings 一并移除喵~

  home.activation.mergeYouTubeMusicSettings = mergeJson {
    target = "${config.xdg.configHome}/YouTube Music/config.json";
    source = youtubeMusicSettings;
  };
}
