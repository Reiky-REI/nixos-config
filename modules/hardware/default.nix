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

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      intel-media-driver
      intel-vaapi-driver
    ];
  };

  hardware.enableAllFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;

  environment.systemPackages =
    with pkgs; [
      pciutils
      ffmpeg
      libva
      libva-utils
    ]
    ++ lib.optionals (config.meow.enabled ? "bluetooth") [bluez];
}
