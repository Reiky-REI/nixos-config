{pkgs, ...}: {
  imports = [
    ./claude-code.nix
  ];

  home.packages = with pkgs; [
    typst
    nodejs

    # Python with minl.ai 依赖 (使用 withPackages 确保依赖完整)
    (python3.withPackages (ps: with ps; [
      pip
      anthropic    # API 调用 (支持 mimo-v2.5)
      pyqt6        # 浮窗 UI
      pynput       # 快捷键监听
      sounddevice  # 语音输入
      numpy        # 数值计算
    ]))

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
