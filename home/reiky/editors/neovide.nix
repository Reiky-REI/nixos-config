{
  pkgs,
  pkgs-unstable,
  ...
}: {
  programs.neovide = {
    enable = true;
    package = pkgs-unstable.neovide;
    settings = {
      no_idle = true;
    };
  };
}
