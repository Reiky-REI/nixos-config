{pkgs, ...}: {
  imports = [
    ./claude-code.nix
  ];

  home.packages = with pkgs; [
    typst
    nodejs
    python3

    # minl.ai 依赖
    python3Packages.pip
    python3Packages.anthropic    # API 调用 (支持 mimo-v2.5)
    python3Packages.pyqt6        # 浮窗 UI
    python3Packages.pynput       # 快捷键监听
    python3Packages.sounddevice  # 语音输入
    python3Packages.numpy        # 数值计算

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
