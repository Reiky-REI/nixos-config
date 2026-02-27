{pkgs, ...}: {
  home.packages = with pkgs; [
    basedpyright
    rust-analyzer
    typst

    nodejs_24
    pnpm_9

    # rustup
    rustc
    cargo
    rustfmt

    go

    python314
    uv

    gcc15
    gdb
    pkg-config
    cmake
    ninja
  ];
}
