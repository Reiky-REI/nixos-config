#!/usr/bin/env bash
# 壁纸切换 (rofi 菜单) — 由 niri 快捷键 Mod+Shift+W 调用。
#
# 渲染方式 (2026-09-26 起): Noctalia 自带壁纸 (noctalia-background 顶层 layer),
#   静态图通过 `noctalia-shell ipc call wallpaper set <path> <screen>` 设置;
#   原 awww/swww 守护已弃用并从系统移除 (它渲染的 background layer 会被
#   Noctalia 顶层背景遮住, 属于重复渲染)。
#
# 视频壁纸: mpvpaper (注意: 同样位于 background layer, 可能被 Noctalia 顶层背景遮挡;
#   彻底方案是启用 Noctalia 的 video-wallpaper 插件, 属后续事项)。
set -euo pipefail

STATIC_DIR="$HOME/Pictures/Wallpapers/static"
VIDEO_DIRS=("$HOME/Pictures/Wallpapers/videos")
ROFI_THEME="${ROFI_THEME:-$HOME/.config/rofi/themes/wallpaper_2_line.rasi}"

get_all_outputs() {
  if command -v niri >/dev/null 2>&1; then
    niri msg outputs 2>/dev/null | grep -oP 'Output "\K[^"]+' || echo "eDP-1"
  elif command -v swaymsg >/dev/null 2>&1; then
    swaymsg -t get_outputs 2>/dev/null | jq -r '.[].name' 2>/dev/null || echo "eDP-1"
  else
    echo "eDP-1"
  fi
}

set_wallpaper() {
  local path="$1" out
  if ! command -v noctalia-shell >/dev/null 2>&1; then
    echo "找不到 noctalia-shell, 无法设置壁纸" >&2
    return 1
  fi
  while IFS= read -r out; do
    [ -n "$out" ] && noctalia-shell ipc call wallpaper set "$path" "$out" >/dev/null 2>&1 || true
  done < <(get_all_outputs)
}

mapfile -t IMAGES < <(find -L "$STATIC_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | sort)

VIDEOS=()
for dir in "${VIDEO_DIRS[@]}"; do
  while IFS= read -r f; do
    [ -n "$f" ] && VIDEOS+=("$f")
  done < <(find "$dir" -maxdepth 1 -type f \( -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.webm' -o -iname '*.mov' \) 2>/dev/null)
done

[ ${#IMAGES[@]} -eq 0 ] && [ ${#VIDEOS[@]} -eq 0 ] && { rofi -e "没有找到壁纸文件"; exit 1; }

MENU_ITEMS=""
for wp in "${IMAGES[@]}"; do
    name=$(basename "$wp")
    MENU_ITEMS+="🖼️  $name\0icon\x1f$wp\n"
done
for vp in "${VIDEOS[@]}"; do
    name=$(basename "$vp")
    MENU_ITEMS+="🎬  $name\n"
done

ROFI_CMD=(rofi -dmenu -p "选择壁纸" -i -show-icons)
[ -n "$ROFI_THEME" ] && ROFI_CMD+=(-theme "$ROFI_THEME")

CHOICE=$(printf '%b' "$MENU_ITEMS" | "${ROFI_CMD[@]}")
[ -z "$CHOICE" ] && exit 0

CHOICE_CLEAN="${CHOICE#🖼️  }"
CHOICE_CLEAN="${CHOICE_CLEAN#🎬  }"

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
    while IFS= read -r output; do
      setsid mpvpaper "$output" "$SELECTED" --hwdec=vaapi-copy -o "--loop-file=inf --no-audio --panscan=1.0" >/dev/null 2>&1 &
    done < <(get_all_outputs)
    if command -v notify-send >/dev/null 2>&1; then
      notify-send "视频壁纸已启动" "$(basename "$SELECTED")"
    fi
    ;;
  *)
    pkill mpvpaper 2>/dev/null || true
    set_wallpaper "$SELECTED"
    if command -v notify-send >/dev/null 2>&1; then
      notify-send "壁纸已切换" "$(basename "$SELECTED")" -i "$SELECTED"
    fi
    ;;
esac
