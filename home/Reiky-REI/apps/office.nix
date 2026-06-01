{pkgs, ...}: {
  home.packages = with pkgs; [
    obsidian
    kdePackages.dolphin
    wpsoffice-cn
  ];
}
