{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./fcitx5
  ];

  programs.xwayland.enable = true;

  programs.niri.enable = true;

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  services.displayManager.ly.enable = true;

  services.xserver.enable = true;

  programs.steam.enable = true;
  programs.steam.fontPackages = with pkgs; [source-han-sans];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  environment.systemPackages = with pkgs; [
    xwayland-satellite
  ];
}
