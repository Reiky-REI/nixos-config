{pkgs, ...}: {
  # DeepSec 安全平台的 Rust 原生二进制 (来自 Reiky-nixpkgs 私源, 上游 rev 钉死):
  #   - deepsec-tui-native: `deepsec tui` 的终端工作台
  #     (deepsec/cli/tui.py 会在 PATH 上查找该名字)
  #   - deepsec-lsp: 编辑器 LSP 桥接 (VSCode/JetBrains 扩展用)
  #
  # Python 运行时 (deepsec / deepsec-guard CLI) 仍由 ~/WorkSpace/DeepSec 的
  # pixi 环境提供; 这里只声明式安装此前需手动 `cargo build` 缺失的原生二进制。
  # pixi 用于声明式维护 DeepSec 的 Python 环境 (pixi.toml/pixi.lock)。
  home.packages = [
    pkgs.deepsec-tui
    pkgs.deepsec-lsp
    pkgs.pixi
  ];
}
