{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./hardware-configuration.nix
  ];

  boot.kernelParams = ["ahci.mobile_lpm_policy=1"];
  boot.kernelPackages = pkgs.linuxPackages;

  boot.extraModprobeConfig = ''
    options btusb enable_autosuspend=0 reset=1
  '';
}
