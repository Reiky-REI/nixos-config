{ config, lib, pkgs, modulesPath, ... }:

{
  # 导入 nixos-generate-config 生成的硬件配置
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../../hardware-configuration.nix
  ];

  # host-specific 硬件参数
  boot.kernelParams = [ "ahci.mobile_lpm_policy=1" ];
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  boot.extraModprobeConfig = ''
    options btusb enable_autosuspend=0 reset=1
  '';
}
