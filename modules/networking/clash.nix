_:
{
  programs.clash-verge = {
    enable = true;
    # package = pkgs-unstable.clash-verge-rev;
    autoStart = false;
    tunMode = true;
    serviceMode = true;
  };
}