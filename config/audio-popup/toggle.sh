#!/usr/bin/env sh
set -eu

app="$HOME/.config/audio-popup/app.tsx"
pidfile="${XDG_RUNTIME_DIR:-/tmp}/audio-popup.pid"
logfile="/tmp/audio-popup.log"

if [ -z "${GI_TYPELIB_PATH:-}" ] || ! printf '%s' "$GI_TYPELIB_PATH" | grep -q 'astal-wireplumber'; then
  astal_wp_path="$(nix eval --raw nixpkgs#astal.wireplumber.outPath 2>/dev/null || true)"
  if [ -n "$astal_wp_path" ]; then
    export GI_TYPELIB_PATH="$astal_wp_path/lib/girepository-1.0:${GI_TYPELIB_PATH:-}"
  fi
fi

if [ -s "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
  kill "$(cat "$pidfile")" 2>/dev/null || true
  rm -f "$pidfile"
  exit 0
fi

rm -f "$pidfile"
: > "$logfile"
nohup ags run "$app" >>"$logfile" 2>&1 &
echo "$!" > "$pidfile"
