{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./fcitx5
    ./ly
  ];

  programs.xwayland.enable = true;

  programs.niri.enable = true;

  services.xserver.enable = true;

  programs.steam.enable = true;
  programs.steam.fontPackages = with pkgs; [source-han-sans];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  environment.systemPackages = with pkgs; [
    xwayland-satellite
    # 屏幕背光控制 (niri / ly TTY 亮度键都需要)
    brightnessctl
  ];

  # backlight 设备权限: video 组可写
  services.udev.extraRules = ''
    SUBSYSTEM=="backlight", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
    SUBSYSTEM=="leds", KERNEL=="*kbd*", ACTION=="add", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/leds/%k/brightness", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/leds/%k/brightness"
  '';

  # TTY/ly 界面亮度键: acpid 捕获 ACPI video 事件调背光
  # 有图形会话时跳过, 避免与 niri 的 XF86 绑定重复处理
  services.acpid = {
    enable = true;
    handlers = {
      brightness-up = {
        event = "video/brightnessup.*";
        action = ''
          if loginctl list-sessions --no-legend | grep -q seat0; then exit 0; fi
          ${pkgs.brightnessctl}/bin/brightnessctl --class=backlight set +10%
        '';
      };
      brightness-down = {
        event = "video/brightnessdown.*";
        action = ''
          if loginctl list-sessions --no-legend | grep -q seat0; then exit 0; fi
          ${pkgs.brightnessctl}/bin/brightnessctl --class=backlight set 10%-
        '';
      };
    };
  };
}
