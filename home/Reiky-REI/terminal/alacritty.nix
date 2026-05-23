_: {
  programs.alacritty = {
    enable = true;
  };

  programs.alacritty.settings = {
    font = {
      normal.family = "FiraCode Nerd Font";
      normal.style = "Regular";
      size = 12.0;
    };
  };

  # catppuccin.alacritty = {
  #   enable = true;
  #   flavor = "mocha";
  # };
}
