{pkgs, ...}: {
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
}
