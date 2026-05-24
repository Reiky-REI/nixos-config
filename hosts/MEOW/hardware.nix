{ config, lib, pkgs, modulesPath, ... }:

let
  patchedKernel = pkgs.linux_7_0.override {
    kernelPatches = [
      {
        name = "btmtk-wmt-fix";
        patch = ./../../patches/btmtk-wmt-fix.patch;
      }
    ];
  };
in {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../../hardware-configuration.nix
  ];

  boot.kernelParams = [ "ahci.mobile_lpm_policy=1" ];
  boot.kernelPackages = pkgs.linuxPackagesFor patchedKernel;

  boot.extraModprobeConfig = ''
    options btusb enable_autosuspend=0 reset=1
  '';
}
