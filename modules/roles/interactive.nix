{
  config,
  lib,
  pkgs,
  ...
}: let
  roles = config.meow.roles;
  hasRole = role: builtins.elem role roles;
  hasDesktop = config.meow.enabled ? "compositor-niri";
  hasInteractiveShell = builtins.any hasRole ["workstation" "devbox" "embedded"];
  hasInteractiveAdmin = builtins.any hasRole ["workstation" "devbox"];
in {
  config = lib.mkMerge [
    (lib.mkIf hasDesktop {
      fonts.packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        # Static Chinese TTF remains available for applications with older font stacks.
        wqy_microhei
        dejavu_fonts
        nerd-fonts.fira-code
        nerd-fonts.jetbrains-mono
      ];

      fonts.enableDefaultPackages = true;
      fonts.fontconfig = {
        enable = true;
        defaultFonts = {
          serif = ["Noto Serif CJK SC" "Noto Serif"];
          sansSerif = ["Noto Sans CJK SC" "Noto Sans"];
          monospace = ["Fira Code" "Noto Sans Mono CJK SC"];
        };
      };
    })

    (lib.mkIf hasInteractiveShell {
      programs.zsh.enable = true;
    })

    (lib.mkIf hasInteractiveAdmin {
      security.sudo.wheelNeedsPassword = false;
      security.polkit.extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (subject.isInGroup("wheel")) {
            return polkit.Result.YES;
          }
        });
      '';
    })
  ];
}
