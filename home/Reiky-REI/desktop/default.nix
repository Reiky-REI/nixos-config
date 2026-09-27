{
  services.polkit-gnome.enable = true;
  services.swaync.enable = true;
  # Noctalia owns idle management; enabling an empty swayidle config causes a crash loop.
  services.swayidle.enable = false;

  imports = [
    ./capture
    ./niri
    ./rofi
    ./hyprlock
    ./wallpaper
    ./noctalia.nix
  ];
}
