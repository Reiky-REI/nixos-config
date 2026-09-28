{pkgs, ...}: {
  # QQ 由 Nix 提供；AstrBot 与 NapCat 已于 2026-09-28 退役喵~
  home.packages = with pkgs; [
    qq
  ];
}
