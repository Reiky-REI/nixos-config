{
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    typst
    nodejs
    python3
    go
    gcc
    cmake
    gnumake
    cargo
    rustc
    rustfmt
    lua
    lua-language-server
    nil
    nixfmt-rfc-style
  ];
}
