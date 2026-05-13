#!/usr/bin/env bash
set -u

app="${1:-}"

case "$app" in
  signal)
    hyprctl dispatch workspace 7 >/dev/null 2>&1 || true
    hyprctl dispatch focuswindow 'class:signal' >/dev/null 2>&1 || true
    ;;
  whatsapp)
    hyprctl dispatch workspace 7 >/dev/null 2>&1 || true
    if ! hyprctl dispatch focuswindow 'class:com.github.dagmoller.whatsapp-electron' >/dev/null 2>&1; then
      if ! hyprctl dispatch focuswindow 'title:WhatsApp.*' >/dev/null 2>&1; then
        gtk-launch com.github.dagmoller.whatsapp-electron >/dev/null 2>&1 &
      fi
    fi
    ;;
esac
