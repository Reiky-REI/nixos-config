{
  lib,
  meow,
  ...
}: {
  programs.imv.enable = lib.mkIf (builtins.elem "compositor-niri" meow.features) true;
}
