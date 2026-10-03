{pkgs, ...}: let
  # 同 Zen 的输入法候选窗 workaround (见 lib/mk-host.nix 注释):
  # 全局 GTK_IM_MODULE=fcitx 会让 GTK3 选 fcitx5-gtk 的 dbus 模块 (im-fcitx5.so),
  # 候选窗由客户端自绘 -> 无 Catppuccin 主题, 只有原生灰白。
  # 强制 GTK_IM_MODULE=wayland -> GTK3 内置 im-wayland.so -> Wayland text-input-v3,
  # 由 fcitx5 waylandim + classicui 在 compositor input-popup 上绘制主题候选窗。
  # Tolaria 为 GTK3/WebKitGTK 且原生跑 Wayland, 故安全 (X11/XWayland 应用不能这么设)。
  tolaria = pkgs.tolaria.overrideAttrs (old: {
    preFixup =
      (old.preFixup or "")
      + ''
        gappsWrapperArgs+=( --set GTK_IM_MODULE wayland )
      '';
  });
in {
  # Tolaria: 桌面端 Markdown 知识库管理应用 (Tauri 2)。
  # 由个人私源 Reiky-nixpkgs 以 overlay 提供 (nixpkgs 未收录, 见 flake.nix inputs)。
  # 现为 .deb 打包, 原生 Wayland 运行; niri 实测 app-id="tolaria" (小写)。
  home.packages = [tolaria];
}
