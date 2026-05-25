{pkgs, ...}: {
  home.packages = with pkgs; [
    obsidian
    logseq
    kdePackages.dolphin
    wpsoffice-cn
  ];
}
