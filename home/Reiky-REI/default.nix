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
  ];

  home.packages = with pkgs; [
    libnotify
  ];

  # 自动创建截图文件夹
  home.activation.ensureScreenshotDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "${config.home.homeDirectory}/screenshot"
  '';

  services.polkit-gnome.enable = true;
  services.swaync.enable = true;
  services.swayidle.enable = true;

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
