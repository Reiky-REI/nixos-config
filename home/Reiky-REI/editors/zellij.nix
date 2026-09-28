_: {
  programs.zellij.enable = true;
  programs.zellij.extraConfig = builtins.readFile ./zellij.kdl;
}
