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
  # 有 active 图形会话 (wayland/x11) 时跳过, 避免与 niri 的 XF86 绑定重复处理
  # 注意: 不能用 grep seat0 判断 — ly 登录界面时 logind 会给 tty1 挂 seat0 会话,
  # 导致 handler 误判"有图形会话"而跳过, ly 界面亮度键失效
  services.acpid = {
    enable = true;
    handlers = {
      brightness-up = {
        event = "video/brightnessup.*";
        action = ''
          # 有 active wayland/x11 会话(桌面)时跳过, 由 niri 处理; ly TTY 界面则 acpid 处理
          for s in $(loginctl list-sessions --no-legend --no-pager | awk '{print $1}'); do
            t=$(loginctl show-session "$s" -p Type --value 2>/dev/null)
            a=$(loginctl show-session "$s" -p Active --value 2>/dev/null)
            if { [ "$t" = wayland ] || [ "$t" = x11 ]; } && [ "$a" = yes ]; then exit 0; fi
          done
          ${pkgs.brightnessctl}/bin/brightnessctl --class=backlight set +10%
        '';
      };
      brightness-down = {
        event = "video/brightnessdown.*";
        action = ''
          # 有 active wayland/x11 会话(桌面)时跳过, 由 niri 处理; ly TTY 界面则 acpid 处理
          for s in $(loginctl list-sessions --no-legend --no-pager | awk '{print $1}'); do
            t=$(loginctl show-session "$s" -p Type --value 2>/dev/null)
            a=$(loginctl show-session "$s" -p Active --value 2>/dev/null)
            if { [ "$t" = wayland ] || [ "$t" = x11 ]; } && [ "$a" = yes ]; then exit 0; fi
          done
          ${pkgs.brightnessctl}/bin/brightnessctl --class=backlight set 10%-
        '';
      };
    };
  };
}
