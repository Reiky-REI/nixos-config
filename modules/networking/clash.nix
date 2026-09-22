{
  config,
  lib,
  ...
}: {
  programs.clash-verge = lib.mkIf (config.meow.enabled ? "clash") {
    enable = true;
    # package = pkgs-unstable.clash-verge-rev;
    autoStart = false;
    tunMode = true;
    serviceMode = true;
  };
}
