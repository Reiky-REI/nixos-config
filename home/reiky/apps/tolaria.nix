{pkgs, ...}: {
  # Tolaria: 桌面端 Markdown 知识库管理应用 (Tauri 2)。
  # 由个人私源 Reiky-nixpkgs 以 overlay 提供 (nixpkgs 未收录, 见 flake.nix inputs)。
  # 上游 AppImage 自带 webkit 密封运行时, 启动强制 GDK_BACKEND=x11 经 XWayland 运行;
  # niri 实测 app-id="Tolaria"(大写), 故窗口规则按此匹配。
  home.packages = [pkgs.tolaria];
}
