{
  config,
  fullName,
  lib,
  pkgs,
  username,
  ...
}: {
  imports = [
    ./hardware.nix
    ../../modules
  ];

  networking.hostName = "NixMEOW";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.${username} = {
    description = "__${fullName}__";
    isNormalUser = true;
    home = "/home/${username}";
    shell = pkgs.zsh;
    ignoreShellProgramCheck = true;
    hashedPassword = "$y$j9T$RQ9/Mj/mI5O8AhOnB.3gJ/$mRmKCYV3q7zKoFF1asu5oZNfBNRE4uHDloKQM7Eq5G3";
    extraGroups = ["wheel" "networkmanager" "audio" "input" "video" "docker" "kvm" "libvirtd" "waydroid"];
  };

  system.stateVersion = "25.05";
}
