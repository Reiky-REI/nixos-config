{...}: {
  programs.btop.enable = true;
  programs.cava.enable = true;
  home.file.".config/btop/btop.conf".source = ./btop.conf;
  home.file.".config/cava" = {
    source = ./cava;
    recursive = true;
  };
}
