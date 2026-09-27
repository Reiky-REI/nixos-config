{
  config,
  pkgs,
  lib,
  meow,
  ...
}: let
  # MikuCat 光标主题打包
  micucat-cursor = pkgs.runCommand "MikuCat" {} ''
    mkdir -p $out/share/icons/MikuCat
    cp -r ${../../pkgs/cursors/MikuCat}/* $out/share/icons/MikuCat/
  '';

  hasDesktop = builtins.elem "compositor-niri" meow.features;
  isWorkstation = builtins.elem "workstation" meow.roles;
  isDeveloperHost = builtins.any (role: builtins.elem role meow.roles) ["workstation" "devbox" "server"];
  hasBacklight = builtins.elem "backlight" meow.features;
in {
  # User environment groups follow host role/capabilities, not a WSL-vs-laptop special case.
  imports =
    [
      ./shell
      ./tools
    ]
    ++ lib.optionals isDeveloperHost [
      ./editors
      ./dev
    ]
    ++ lib.optionals hasDesktop [
      ./terminal
      ./editors/desktop.nix
      ./tools/desktop.nix
      ./desktop
    ]
    ++ lib.optionals isWorkstation [
      ./apps
      ./music
      ./tools/mihomo.nix
    ]
    ++ lib.optionals (isWorkstation && hasBacklight) [./tools/kbdlight.nix];

  home.packages = lib.optionals hasDesktop [pkgs.libnotify];

  # 自动创建截图文件夹
  home.activation.ensureScreenshotDir = lib.mkIf hasDesktop (lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "${config.home.homeDirectory}/screenshot"
  '');

  # 移除本地旧 fcitx5 config, 防止覆盖 NixOS 生成的 /etc/xdg/fcitx5/config
  # (fcitx5 优先级 ~/.config > /etc/xdg, 本地旧文件会导致快捷键等 NixOS 设置失效)
  home.activation.cleanFcitx5Config =
    lib.mkIf (builtins.elem "fcitx5" meow.features)
    (lib.hm.dag.entryAfter ["writeBoundary"] ''
      rm -f "${config.home.homeDirectory}/.config/fcitx5/config"
    '');

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

  xdg.mimeApps.enable = lib.mkIf hasDesktop true;
  xdg.mimeApps.defaultApplications = lib.mkIf hasDesktop {
    "image/png" = ["imv.desktop"];
    "image/jpeg" = ["imv.desktop"];
    "image/gif" = ["imv.desktop"];
    "text/html" = "google-chrome.desktop";
    "x-scheme-handler/http" = "google-chrome.desktop";
    "x-scheme-handler/https" = "google-chrome.desktop";
  };

  # 光标配置 - MikuCat
  home.pointerCursor = lib.mkIf hasDesktop {
    enable = true;
    package = micucat-cursor;
    name = "MikuCat";
    size = 32;
  };

  home.sessionVariables =
    {
      EDITOR = "nvim";
      VISUAL = "nvim";
      PATH = "$HOME/.local/bin:$PATH";
      LANG = "en_US.UTF-8";
      LC_CTYPE = "zh_CN.UTF-8";
      LC_MESSAGES = "en_US.UTF-8";
    }
    // lib.optionalAttrs hasDesktop {TERMINAL = "kitty";};

  home.stateVersion = "25.11";
  home.enableNixpkgsReleaseCheck = true;
}
