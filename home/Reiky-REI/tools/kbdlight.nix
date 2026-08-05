{
  pkgs,
  config,
  ...
}: {
  # kbdlight: COLORFIRE MEOW R16 键盘背光控制 (基于补丁版 tuxedo-keyboard)
  # 使用: kbdlight off / kbdlight on / kbdlight 50 / kbdlight #ff0000 / kbdlight 255 0 128
  home.packages = [
    (pkgs.writeShellScriptBin "kbdlight" ''
      set -euo pipefail
      LED=/sys/class/leds/rgb:kbdlight

      die() { echo "kbdlight: $*" >&2; exit 1; }

      wait_for_led() {
        local tries=50
        while [ ! -e "$LED/brightness" ] && [ "$tries" -gt 0 ]; do
          sleep 0.1; tries=$((tries - 1))
        done
        [ -e "$LED/brightness" ] || die "no backlight at $LED (tuxedo_keyboard 未加载?)"
      }

      max() { cat "$LED/max_brightness"; }

      pct_to_raw() { local p="$1" m; m=$(max); echo $(( (p * m + 50) / 100 )); }

      write_attr() { # write_attr <file> <value>
        local f="$LED/$1" v="$2"
        if [ -w "$f" ]; then echo "$v" > "$f"
        else die "cannot write $f (需要 video 组权限或 sudo)"; fi
      }

      cmd="''${1:-}"
      [ -n "$cmd" ] || { echo "用法: kbdlight [off|on|0-100|#rrggbb|r g b]"; exit 1; }
      wait_for_led

      case "$cmd" in
        off|0)
          write_attr brightness 0
          ;;
        on|1)
          write_attr brightness "$(max)"
          ;;
        [0-9]*)
          write_attr brightness "$(pct_to_raw "$cmd")"
          ;;
        \#*)
          hex=''${cmd#'#'}
          r=$((16#''${hex:0:2})); g=$((16#''${hex:2:2})); b=$((16#''${hex:4:2}))
          write_attr multi_intensity "$r $g $b"
          write_attr brightness "$(cat "$LED/brightness")"
          ;;
        *)
          r="$1"; g="$2"; b="$3"
          write_attr multi_intensity "$r $g $b"
          write_attr brightness "$(cat "$LED/brightness")"
          ;;
      esac
    '')
  ];

  # 同步脚本: 颜色跟随 Noctalia 主题, 亮度跟随屏幕亮度
  home.file.".local/bin/kbdlight-sync.py".text = ''
    #!/usr/bin/env python3
    """自动同步键盘背光: 颜色跟随 Noctalia 主题, 亮度跟随屏幕亮度."""
    import json
    import os
    import sys

    LED = "/sys/class/leds/rgb:kbdlight"
    COLORS = os.path.expanduser("~/.config/noctalia/colors.json")
    SCREEN_BL = "/sys/class/backlight/amdgpu_bl2"
    OFF_MARKER = "/tmp/kbdlight-off"

    def read_int(path):
        try:
            with open(path) as f:
                return int(f.read().strip())
        except (OSError, ValueError):
            return None

    def apply_color():
        """从 Noctalia colors.json 读 mPrimary, 写到键盘背光 RGB."""
        if not os.path.exists(COLORS):
            return
        try:
            with open(COLORS) as f:
                data = json.load(f)
            hex_color = data.get("mPrimary", "#8839ef").lstrip("#")
            if len(hex_color) != 6:
                return
            r, g, b = (int(hex_color[i:i+2], 16) for i in (0, 2, 4))
            with open(f"{LED}/multi_intensity", "w") as f:
                f.write(f"{r} {g} {b}\n")
        except (OSError, ValueError, KeyError):
            pass

    def apply_brightness():
        """屏幕亮度比例 → 键盘背光亮度."""
        s = read_int(f"{SCREEN_BL}/brightness")
        s_max = read_int(f"{SCREEN_BL}/max_brightness")
        k_max = read_int(f"{LED}/max_brightness")
        if s is None or s_max is None or k_max is None or s_max == 0:
            return
        ratio = s / s_max
        target = max(1, int(k_max * ratio))
        with open(f"{LED}/brightness", "w") as f:
            f.write(f"{target}\n")

    def main():
        if not os.path.exists(f"{LED}/brightness"):
            sys.exit(0)
        if "--color-only" in sys.argv:
            apply_color()
            return
        if "--brightness-only" in sys.argv:
            apply_brightness()
            return
        apply_color()
        apply_brightness()

    if __name__ == "__main__":
        main()
  '';

  # 熄屏 hook: 关键盘背光 + 记录状态; 恢复逻辑在 kbdlight-sync 守护中
  home.file.".local/bin/kbdlight-niri-off.sh".text = ''
    #!/usr/bin/env bash
    set -euo pipefail
    LED=/sys/class/leds/rgb:kbdlight
    if [ -e "$LED/brightness" ]; then
      echo 0 > "$LED/brightness" 2>/dev/null || true
    fi
    touch /tmp/kbdlight-off
    sleep 0.2
    exec niri msg action power-off-monitors
  '';

  # kbdlight-sync 守护: inotify 监听主题色+屏幕亮度, 同时监听 niri 事件流检测唤醒
  systemd.user.services.kbdlight-sync = {
    Unit = {
      Description = "Sync keyboard backlight with Noctalia theme, screen brightness and DPMS";
      After = ["graphical-session.target"];
    };
    Service = {
      ExecStart = pkgs.writeShellScript "kbdlight-sync-daemon" ''
        LED=/sys/class/leds/rgb:kbdlight
        # 等待驱动就绪
        for i in $(seq 1 50); do
          [ -e "$LED/brightness" ] && break
          sleep 0.2
        done
        [ -e "$LED/brightness" ] || exit 0

        sync_py="${config.home.homeDirectory}/.local/bin/kbdlight-sync.py"

        # 先应用一次当前状态
        python3 "$sync_py" || true

        # 并行: (1) inotify 监听文件变化 (2) niri 事件流检测唤醒恢复
        (
          ${pkgs.inotify-tools}/bin/inotifywait -m -e modify --format '%w' \
            "${config.home.homeDirectory}/.config/noctalia/colors.json" \
            /sys/class/backlight/amdgpu_bl2/brightness \
            | while read -r changed; do
                # 若在熄屏状态(有 off 标记), 仅更新颜色, 不恢复亮度
                if [ -e /tmp/kbdlight-off ]; then
                  python3 "$sync_py" --color-only || true
                else
                  python3 "$sync_py" || true
                fi
              done
        ) &

        # (2) niri 事件流: 检测到窗口/工作区变化视为"用户回来了", 移除 off 标记并恢复
        (
          while true; do
            if timeout 120 niri msg event-stream 2>/dev/null | grep -m1 -qE "Windows changed|Workspaces changed|Outputs changed"; then
              if [ -e /tmp/kbdlight-off ]; then
                rm -f /tmp/kbdlight-off
                python3 "$sync_py" || true
              fi
            fi
          done
        ) &

        wait
      '';
      Restart = "on-failure";
      RestartSec = "5";
    };
    Install.WantedBy = ["graphical-session.target"];
  };
}
