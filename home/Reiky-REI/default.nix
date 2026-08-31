{
  config,
  pkgs,
  lib,
  ...
}: let
  # MikuCat 光标主题打包
  micucat-cursor = pkgs.runCommand "MikuCat" {} ''
    mkdir -p $out/share/icons/MikuCat
    cp -r ${../../pkgs/cursors/MikuCat}/* $out/share/icons/MikuCat/
  '';

  # 动态导入 ~/.config/home-manager/services/ 下的所有 .nix 文件
  # 新增用户服务只需在该目录创建 .nix 文件, 无需修改此文件
  userServicesDir = "/home/Reiky-REI/.config/home-manager/services";
  userServices =
    if builtins.pathExists userServicesDir
    then let
      entries = builtins.readDir userServicesDir;
      nixFiles = builtins.filter (name: builtins.match ".*\\.nix" name != null) (builtins.attrNames entries);
    in
      map (f: "${userServicesDir}/${f}") nixFiles
    else [];
in {
  imports = [
    ./shell
    ./terminal
    ./music
    ./desktop
    ./apps
    ./tools
    ./editors
    ./dev
  ] ++ userServices;

  home.packages = with pkgs; [
    libnotify
  ];

  # 自动创建截图文件夹
  home.activation.ensureScreenshotDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "${config.home.homeDirectory}/screenshot"
  '';

  # 移除本地旧 fcitx5 config, 防止覆盖 NixOS 生成的 /etc/xdg/fcitx5/config
  # (fcitx5 优先级 ~/.config > /etc/xdg, 本地旧文件会导致快捷键等 NixOS 设置失效)
  home.activation.cleanFcitx5Config = lib.hm.dag.entryAfter ["writeBoundary"] ''
    rm -f "${config.home.homeDirectory}/.config/fcitx5/config"
  '';

  services.polkit-gnome.enable = true;
  services.swaync.enable = true;
  # 2026-09-01: idle 管理已由 noctalia-shell 内置 (settings.json idle.*), swayidle 未配任何 event
  # → 空配置秒退 → start-limit-hit 崩溃循环, 纯日志噪声, 禁用喵~ (如需启用必须配 timeout 事件)
  services.swayidle.enable = false;

  # catppuccin.swaync = {
  #   enable = true;
  #   flavor = "mocha";
  # };

  # services.mako.enable = true;
  # catppuccin.mako = {
  #   enable = true;
  #   accent = "mauve";
  #   flavor = "mocha";
  # };

  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = {
    "image/png" = ["imv.desktop"];
    "image/jpeg" = ["imv.desktop"];
    "image/gif" = ["imv.desktop"];
    "text/html" = "google-chrome.desktop";
    "x-scheme-handler/http" = "google-chrome.desktop";
    "x-scheme-handler/https" = "google-chrome.desktop";
  };

  # 光标配置 - MikuCat
  home.pointerCursor = {
    enable = true;
    package = micucat-cursor;
    name = "MikuCat";
    size = 32;
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    TERMINAL = "kitty";
    PATH = "$HOME/.local/bin:$PATH";
    LANG = "en_US.UTF-8";
    LC_CTYPE = "zh_CN.UTF-8";
    LC_MESSAGES = "en_US.UTF-8";
  };

  home.stateVersion = "25.11";
  home.enableNixpkgsReleaseCheck = true;
}
