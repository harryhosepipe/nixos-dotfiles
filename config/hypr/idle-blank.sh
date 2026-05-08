#!/usr/bin/env sh
set -eu

class="hypr-idle-blank"

case "${1:-}" in
  on)
    if pgrep -f "alacritty.*${class}" >/dev/null 2>&1; then
      exit 0
    fi

    alacritty \
      --class "$class,$class" \
      -o window.decorations=None \
      -o window.opacity=1.0 \
      -o colors.primary.background="#000000" \
      -o colors.primary.foreground="#000000" \
      -e sh -c 'tput civis 2>/dev/null || true; clear; exec sleep infinity' &

    sleep 0.2
    hyprctl dispatch focuswindow "class:${class}" >/dev/null 2>&1 || true
    hyprctl dispatch fullscreen 0 >/dev/null 2>&1 || true
    ;;
  off)
    pkill -f "alacritty.*${class}" >/dev/null 2>&1 || true
    ;;
  *)
    printf 'usage: %s on|off\n' "$0" >&2
    exit 2
    ;;
esac
