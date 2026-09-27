{
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    ./gpu
    ./bluetooth/btmtk-fix.nix
  ];

  hardware.bluetooth.enable = lib.mkIf (config.meow.enabled ? "bluetooth") true;
  services.blueman.enable = lib.mkIf (config.meow.enabled ? "bluetooth") true;

  hardware.graphics = lib.mkIf (config.meow.enabled ? "compositor-niri") {
    enable = true;
    enable32Bit = true;
  };

  environment.systemPackages = with pkgs;
    [pciutils]
    ++ lib.optionals (config.meow.enabled ? "compositor-niri") [
      ffmpeg
      libva
      libva-utils
    ]
    ++ lib.optionals (config.meow.enabled ? "bluetooth") [bluez];
}
