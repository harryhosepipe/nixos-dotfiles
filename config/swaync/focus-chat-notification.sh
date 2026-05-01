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
    hyprctl dispatch focuswindow 'title:WhatsApp Electron.*' >/dev/null 2>&1 || true
    ;;
esac
