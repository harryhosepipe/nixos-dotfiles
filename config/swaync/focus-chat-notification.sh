#!/usr/bin/env bash
set -u

app="${1:-}"

case "$app" in
  signal)
    hyprctl dispatch workspace 7 >/dev/null 2>&1 || true
    if ! hyprctl dispatch focuswindow 'class:signal' >/dev/null 2>&1; then
      gtk-launch signal-desktop >/dev/null 2>&1 &
    fi
    ;;
  whatsapp)
    hyprctl dispatch workspace 7 >/dev/null 2>&1 || true
    if ! hyprctl dispatch focuswindow 'title:WhatsApp Electron.*' >/dev/null 2>&1; then
      if ! hyprctl dispatch focuswindow 'class:com.github.dagmoller.whatsapp-electron' >/dev/null 2>&1; then
        gtk-launch com.github.dagmoller.whatsapp-electron >/dev/null 2>&1 &
      fi
    fi
    ;;
  telegram)
    hyprctl dispatch workspace 7 >/dev/null 2>&1 || true
    if ! hyprctl dispatch focuswindow 'class:org.telegram.desktop.*' >/dev/null 2>&1; then
      if ! hyprctl dispatch focuswindow 'title:Telegram.*' >/dev/null 2>&1; then
        gtk-launch org.telegram.desktop >/dev/null 2>&1 &
      fi
    fi
    ;;
esac
