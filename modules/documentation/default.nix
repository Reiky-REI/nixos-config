{
  config,
  lib,
  pkgs,
  ...
}: let
  wantsDocs = builtins.any (role: builtins.elem role config.meow.roles) ["workstation" "devbox"];
in {
  environment.systemPackages = lib.optionals wantsDocs (with pkgs; [
    man-pages
    man-pages-posix
    stdman
  ]);
  documentation = lib.mkIf wantsDocs {
    enable = true;
    man = {
      enable = true;
      cache.enable = true;
      man-db = {
        enable = true;
      };
    };
  };
}
