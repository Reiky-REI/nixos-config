{pkgs, ...}: {
  home.packages = with pkgs; [
    tty-clock
    tree
    unzip
    zip
    tldr
    entr
    evtest

    wlr-randr

    imagemagick
    grim
    slurp
    satty
    wf-recorder
    wl-clipboard
    cliphist
    wayvnc
  ];
}
