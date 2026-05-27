#!/usr/bin/env bash
set -euo pipefail

CMD="${1:-toggle}"
STATIC_DIR="$HOME/Pictures/Wallpapers/static"
VIDEO_DIRS=("$HOME/Pictures/Wallpapers/videos" "$HOME/Downloads" "$HOME/download")

case "$CMD" in
  start)
    pkill mpvpaper 2>/dev/null || true
    for dir in "${VIDEO_DIRS[@]}"; do
      mapfile -t VIDEOS < <(find "$dir" -maxdepth 1 -type f \( -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.webm' \) 2>/dev/null)
      [ ${#VIDEOS[@]} -gt 0 ] && break
    done
    [ ${#VIDEOS[@]} -eq 0 ] && { rofi -e "没有找到视频文件"; exit 1; }
    VIDEO="${VIDEOS[$RANDOM % ${#VIDEOS[@]}]}"
    mpvpaper eDP-1 "$VIDEO" --hwdec=vaapi-copy -o "--loop-file=inf --no-audio"
    ;;
  stop)
    pkill mpvpaper 2>/dev/null || true
    mapfile -t IMGS < <(find "$STATIC_DIR" -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null)
    if [ ${#IMGS[@]} -gt 0 ]; then
      swww img "${IMGS[$RANDOM % ${#IMGS[@]}]}" --transition-type any --transition-duration 2
    fi
    ;;
  toggle)
    if pgrep mpvpaper >/dev/null 2>&1; then
      "$0" stop
    else
      "$0" start
    fi
    ;;
esac
