{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./gpu
  ];

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

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

  environment.systemPackages = with pkgs; [
    pciutils
    bluez
    ffmpeg
    libva
    libva-utils
  ];
}
