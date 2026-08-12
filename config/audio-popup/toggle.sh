#!/usr/bin/env sh
set -eu

script_dir="$(CDPATH= cd -- "$(dirname -- "$(readlink -f "$0")")" && pwd)"
app="$script_dir/app.tsx"
pidfile="${XDG_RUNTIME_DIR:-/tmp}/audio-popup.pid"
logfile="/tmp/audio-popup.log"

if [ -s "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
  kill "$(cat "$pidfile")" 2>/dev/null || true
  rm -f "$pidfile"
  exit 0
fi

rm -f "$pidfile"
: > "$logfile"
if command -v ags >/dev/null 2>&1 && command -v pactl >/dev/null 2>&1; then
  nohup ags run "$app" >>"$logfile" 2>&1 &
else
  nohup nix shell nixpkgs#ags nixpkgs#pulseaudio -c ags run "$app" >>"$logfile" 2>&1 &
fi
echo "$!" > "$pidfile"
