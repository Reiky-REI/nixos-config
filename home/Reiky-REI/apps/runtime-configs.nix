{
  config,
  lib,
  pkgs,
  ...
}: let
  mergeJson = import ../lib/merge-json-activation.nix {inherit lib pkgs;};
  splayerSettings = pkgs.writeText "splayer-settings.json" (builtins.readFile ./splayer-settings.json);
  youtubeMusicSettings = pkgs.writeText "youtube-music-settings.json" (builtins.readFile ./youtube-music-settings.json);
in {
  home.file.".config/pigma/config.toml".source = ./pigma.toml;

  home.activation.mergeSPlayerSettings = mergeJson {
    target = "${config.xdg.configHome}/SPlayer/config.json";
    source = splayerSettings;
  };

  home.activation.mergeYouTubeMusicSettings = mergeJson {
    target = "${config.xdg.configHome}/YouTube Music/config.json";
    source = youtubeMusicSettings;
  };
}
