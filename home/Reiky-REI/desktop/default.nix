{
  lib,
  meow,
  ...
}: {
  services.polkit-gnome.enable = true;
  services.swaync.enable = true;
  # Noctalia owns idle management; enabling an empty swayidle config causes a crash loop.
  services.swayidle.enable = false;

  imports =
    [
      ./capture
      ./niri
      ./rofi
      ./hyprlock
      ./wallpaper
      ./noctalia.nix
    ]
    ++ lib.optionals (builtins.elem "fcitx5" meow.features) [./fcitx5-settings.nix];
}
