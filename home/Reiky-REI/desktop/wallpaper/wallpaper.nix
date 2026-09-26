{...}: {
  # ===== 壁纸管理 (2026-09-26 重构) =====
  # 渲染: Noctalia 自带壁纸 (noctalia-background 顶层 layer) —— 已弃用 awww/swww 守护
  # 切换: niri 快捷键 Mod+Shift+W -> ~/.config/wallpaper/script/wallpaper-rofi.sh
  #       (rofi 选图, 静态图经 `noctalia-shell ipc call wallpaper set` 交给 Noctalia)
  # 文件: ~/Pictures/Wallpapers/{static,videos} 由用户直接管理, 不经 nix 部署

  home.file.".config/wallpaper/script/wallpaper-rofi.sh" = {
    source = ./wallpaper-rofi.sh;
    executable = true;
    # 该路径此前是历史残留真实文件(非 nix 托管), 不 force 会触发 clobber 报错
    force = true;
  };
}
