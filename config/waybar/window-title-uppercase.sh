#!/usr/bin/env sh

print_title() {
  if [ -z "$title" ] || [ "$title" = "null" ]; then
    title="DESKTOP"
  fi

  title="$(printf '%s\n' "$title" | tr '[:lower:]' '[:upper:]')"

  if [ "$title" != "$last_title" ]; then
    printf '%s\n' "$title"
    last_title="$title"
  fi
}

title="$(hyprctl activewindow -j 2>/dev/null | jq -r '.title // ""' 2>/dev/null)"
print_title

socket="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

# Keep this script running for Waybar. Hyprland writes focus and title changes
# to this socket, so the label updates without waiting for a timer.
nc -U "$socket" 2>/dev/null | while read -r event; do
  case "$event" in
    activewindow\>\>*)
      title="${event#activewindow>>}"
      title="${title#*,}"
      print_title
      ;;
    windowtitlev2\>\>*)
      title="${event#windowtitlev2>>}"
      title="${title#*,}"
      print_title
      ;;
    activewindowv2*|windowtitle*)
      # These events only include the window address, so keep the last title.
      ;;
  esac
done
