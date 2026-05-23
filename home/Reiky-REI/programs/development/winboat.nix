{
  config,
  pkgs,
  ...
}: {
  home.packages = [pkgs.winboat];
}
