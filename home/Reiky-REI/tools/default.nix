{
  lib,
  meow,
  system,
  ...
}: let
  hasAgentTools = builtins.any (role: builtins.elem role meow.roles) ["workstation" "devbox" "server"];
in {
  imports =
    [
      ./essentials.nix
      ./archive.nix
      ./search.nix
      ./viewers.nix
      ./monitors.nix
      ./dsh.nix
    ]
    ++ lib.optionals (hasAgentTools && system == "x86_64-linux") [./opencode.nix];
}
