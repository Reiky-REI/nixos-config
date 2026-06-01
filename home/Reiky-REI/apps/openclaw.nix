{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  inherit (inputs) openclaw;
  system = pkgs.stdenv.hostPlatform.system;
in {
  imports = [openclaw.homeManagerModules.openclaw];

  programs.openclaw = {
    enable = true;
    package = openclaw.packages.${system}.default;

    config = {
      gateway = {
        mode = "local";
        auth.token = "REIKY-OPENCLAW-GATEWAY-2026";
      };

      models.providers.anthropic = {
        baseUrl = "http://127.0.0.1:15721";
        apiKey = "sk-cc-switch-proxy";
      };

      memory.backend = "builtin";
    };

    bundledPlugins = {
      summarize.enable = true;
    };
  };
}
