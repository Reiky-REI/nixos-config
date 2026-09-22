{
  config,
  lib,
  ...
}: {
  imports = [
    ./colors.nix
    ./settings.nix
  ];

  services.displayManager.ly.enable =
    lib.mkIf (config.meow.enabled ? "display-manager-ly")
      true;
}
