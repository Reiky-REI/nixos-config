#!/usr/bin/env bash
set -euo pipefail

STATIC_DIR="$HOME/Pictures/Wallpapers/static"
VIDEO_DIRS=("$HOME/Pictures/Wallpapers/videos" "$HOME/Downloads" "$HOME/download")
ROFI_THEME="${ROFI_THEME:-$HOME/.config/rofi/themes/wallpaper_2_line.rasi}"

# 收集静态壁纸
mapfile -t IMAGES < <(find -L "$STATIC_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | sort)

# 收集视频壁纸
VIDEOS=()
for dir in "${VIDEO_DIRS[@]}"; do
  while IFS= read -r -d '' f; do
    VIDEOS+=("$f")
  done < <(find "$dir" -maxdepth 1 -type f \( -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.webm' -o -iname '*.mov' \) 2>/dev/null | sort -z)
done

[ ${#IMAGES[@]} -eq 0 ] && [ ${#VIDEOS[@]} -eq 0 ] && { rofi -e "没有找到壁纸文件"; exit 1; }

# 构建 rofi 菜单：图片用自身图标，视频标记 🎬
MENU_ITEMS=""
for wp in "${IMAGES[@]}"; do
    name=$(basename "$wp")
    MENU_ITEMS+="$name\0icon\x1f$wp\n"
done
for vp in "${VIDEOS[@]}"; do
    name=$(basename "$vp")
    MENU_ITEMS+="🎬 $name\0icon\x1fvideo-x-generic\n"
done

ROFI_CMD=(rofi -dmenu -p "选择壁纸" -show-icons)
[ -n "$ROFI_THEME" ] && ROFI_CMD+=(-theme "$ROFI_THEME")

CHOICE=$(printf '%b' "$MENU_ITEMS" | "${ROFI_CMD[@]}")
[ -z "$CHOICE" ] && exit 0

# 去掉 🎬 前缀再匹配
CHOICE_CLEAN="${CHOICE#🎬 }"
SELECTED=""
for wp in "${IMAGES[@]}"; do
    [ "$(basename "$wp")" = "$CHOICE_CLEAN" ] && { SELECTED="$wp"; break; }
done
if [ -z "$SELECTED" ]; then
    for vp in "${VIDEOS[@]}"; do
        [ "$(basename "$vp")" = "$CHOICE_CLEAN" ] && { SELECTED="$vp"; break; }
    done
fi

[ -z "$SELECTED" ] && exit 1

case "$SELECTED" in
  *.mp4|*.mkv|*.webm|*.mov)
    pkill mpvpaper 2>/dev/null || true
    mpvpaper eDP-1 "$SELECTED" --hwdec=vaapi-copy -o "--loop-file=inf --no-audio"
    if command -v notify-send >/dev/null 2>&1; then
      notify-send "视频壁纸已启动" "$(basename "$SELECTED")"
    fi
    ;;
  *)
    pkill mpvpaper 2>/dev/null || true
    if ! pgrep -x "swww-daemon" >/dev/null 2>&1; then
      swww-daemon >/dev/null 2>&1 &
      sleep 0.25
    fi
    types=(fade grow outer center wipe wave simple left top right bottom any)
    transition=${types[$RANDOM % ${#types[@]}]}
    swww img "$SELECTED" \
      --transition-type "$transition" \
      --transition-duration 2 \
      --transition-fps 144 \
      --transition-bezier 0.22,1,0.36,1
    if command -v notify-send >/dev/null 2>&1; then
      notify-send "壁纸已切换" "$(basename "$SELECTED") - 效果: $transition" -i "$SELECTED"
    fi
    ;;
esac
