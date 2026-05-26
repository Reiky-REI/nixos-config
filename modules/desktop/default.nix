{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./fcitx5
  ];

  programs.xwayland.enable = true;

  programs.niri.enable = true;

  services.displayManager.ly = {
    enable = true;
    settings = {
      # Catppuccin Mocha 配色
      bg = "0x001e1e2e";
      fg = "0x00cdd6f4";
      border_fg = "0x00cba6f7";
      error_fg = "0x01f38ba8";
      error_bg = "0x001e1e2e";

      # 布局
      hide_borders = false;
      hide_key_hints = false;
      blank_box = true;
      text_in_center = true;
      input_len = 38;
      box_title = "NixMEOW";

      # Colormix 渐变动画
      animation = "colormix";
      colormix_col1 = "0x00cba6f7";
      colormix_col2 = "0x0094e2d5";
      colormix_col3 = "0x00f5c2e7";
      animation_timeout_sec = 0;

      # 大时钟
      bigclock = "en";
      bigclock_12hr = false;
      bigclock_seconds = false;

      # 其他
      clock = "%a %H:%M";
      default_input = "login";
      asterisk = "*";
    };
  };

  services.xserver.enable = true;

  programs.steam.enable = true;
  programs.steam.fontPackages = with pkgs; [source-han-sans];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  environment.systemPackages = with pkgs; [
    xwayland-satellite
  ];
}
