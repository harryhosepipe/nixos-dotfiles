#!/usr/bin/env bash

set -euo pipefail

prompt="  Keyboard shortcuts"
runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
pid_file="${runtime_dir}/waybar-keybinds-overlay.pid"

# A second click closes the palette instead of opening another copy.
if [[ -r "$pid_file" ]]; then
  overlay_pid="$(<"$pid_file")"
  if [[ "$overlay_pid" =~ ^[0-9]+$ ]] &&
    kill -0 "$overlay_pid" 2>/dev/null &&
    [[ "$(<"/proc/${overlay_pid}/comm")" == "wofi" ]]; then
    kill "$overlay_pid"
    exit 0
  fi
  rm -f "$pid_file"
fi

command -v hyprctl >/dev/null 2>&1 || exit 1
command -v jq >/dev/null 2>&1 || exit 1
command -v wofi >/dev/null 2>&1 || exit 1

hyprctl binds -j |
  jq -r '
    def modifiers:
      [
        (if (.modmask / 64 | floor) % 2 == 1 then "Super" else empty end),
        (if (.modmask / 8  | floor) % 2 == 1 then "Alt" else empty end),
        (if (.modmask / 4  | floor) % 2 == 1 then "Ctrl" else empty end),
        (if (.modmask / 1  | floor) % 2 == 1 then "Shift" else empty end)
      ];
    def pretty_key:
      .key
      | gsub("^RETURN$"; "Enter")
      | gsub("^SPACE$"; "Space")
      | gsub("^Escape$"; "Esc")
      | gsub("^comma$"; ",")
      | gsub("^period$"; ".")
      | gsub("^backslash$"; "\\")
      | gsub("^mouse:272$"; "Left click")
      | gsub("^mouse:273$"; "Right click")
      | gsub("^mouse:275$"; "Mouse forward")
      | gsub("^mouse:276$"; "Mouse back")
      | gsub("^mouse_down$"; "Wheel down")
      | gsub("^mouse_up$"; "Wheel up");
    map(select(.has_description and (.description | length > 0)))
    | sort_by(.description)
    | .[]
    | ((modifiers + [pretty_key]) | join(" + ")) as $keys
    | "\($keys)\t\(.description)"
  ' |
  wofi \
    --dmenu \
    --allow-markup \
    --insensitive \
    --matching fuzzy \
    --prompt "$prompt" \
    --style "$HOME/.config/waybar/keybinds-overlay.css" \
    --width 720 \
    --height 620 \
    --cache-file /dev/null \
    >/dev/null &

overlay_pid=$!
printf '%s\n' "$overlay_pid" >"$pid_file"
trap 'rm -f "$pid_file"' EXIT INT TERM
wait "$overlay_pid" || true
