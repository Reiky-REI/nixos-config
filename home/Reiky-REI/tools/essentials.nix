{
  lib,
  meow,
  pkgs,
  ...
}: let
  hasDesktop = builtins.elem "compositor-niri" meow.features;
in {
  home.packages = with pkgs;
    [
      tty-clock
      tree
      unzip
      zip
      tldr
      entr
      evtest

      imagemagick
    ]
    ++ lib.optionals hasDesktop [
      wlr-randr
      grim
      slurp
      satty
      wf-recorder
      wl-clipboard
      cliphist
      wayvnc
    ];
}
