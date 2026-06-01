{pkgs, ...}: {
  imports = [
    ./claude-code.nix
  ];

  home.packages = with pkgs; [
    typst
    nodejs
    python3
    go
    xmake
    gcc
    cmake
    gnumake
    cargo
    rustc
    rustfmt
    lua
    lua-language-server
    nixd
    nixfmt-rfc-style

    # LSP servers
    pyright
    rust-analyzer
    clang-tools
    gopls
    typescript-language-server
  ];
}
