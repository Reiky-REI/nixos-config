{
  lib,
  meow,
  system,
  ...
}: let
  hasAgentTools = builtins.any (role: builtins.elem role meow.roles) ["workstation" "devbox" "server"];
in {
  home.file.".config/gh/config.yml".source = ./gh-config.yml;

  imports =
    [
      ./essentials.nix
      ./archive.nix
      ./search.nix
      ./viewers.nix
      ./monitors.nix
      ./agent-resume.nix
      ./dsh.nix
      ./user-services.nix
    ]
    ++ lib.optionals hasAgentTools [./dsh-profile.nix]
    ++ lib.optionals (hasAgentTools && system == "x86_64-linux") [./opencode.nix];
}
