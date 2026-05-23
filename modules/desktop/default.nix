{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hyprland
    ./niri
    ./noctalia
    ./rofi
    ./fcitx5
    ./wallpaper
  ];

  programs.xwayland.enable = true;

  # Niri
  programs.niri.enable = true;

  # Hyprland
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };
  #services.displayManager.gdm.enable = true;
  #services.displayManager.gdm.wayland = true;
  #services.gnome.gnome-keyring.enable = true;
  #security.pam.services.gdm.enableGnomeKeyring = true;

  # services.displayManager.sddm.enable = true;

  services.displayManager.ly.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";
}
