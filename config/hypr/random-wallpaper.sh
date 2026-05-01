#!/usr/bin/env sh

set -eu

wallpaper_dir="$HOME/Documents/wallpapers"

if [ ! -d "$wallpaper_dir" ]; then
  exit 0
fi

wallpaper_file="$(
  find "$wallpaper_dir" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
    | shuf -n 1
)"

if [ -z "$wallpaper_file" ]; then
  exit 0
fi

# hyprpaper's IPC socket can appear a moment after the process starts.
# Retry briefly so the same script works at login and from a hotkey.
attempt=0
while [ "$attempt" -lt 20 ]; do
  monitor_names="$(hyprctl monitors | awk '/^Monitor / { print $2 }')"

  if [ -n "$monitor_names" ]; then
    applied=1

    for monitor_name in $monitor_names; do
      if ! hyprctl hyprpaper wallpaper "$monitor_name,$wallpaper_file,cover" >/dev/null 2>&1; then
        applied=0
        break
      fi
    done

    if [ "$applied" -eq 1 ]; then
      exit 0
    fi
  fi

  attempt=$((attempt + 1))
  sleep 0.2
done

exit 1
