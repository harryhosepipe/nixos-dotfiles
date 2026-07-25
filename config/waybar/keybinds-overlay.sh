#!/usr/bin/env bash

set -euo pipefail

runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
pid_file="${runtime_dir}/waybar-keybinds-overlay.pid"
overlay_pid=""

# A second click closes the palette instead of opening another copy.
if [[ -r "$pid_file" ]]; then
  overlay_start=""
  read -r overlay_pid overlay_start <"$pid_file" || true
  if [[ "$overlay_pid" =~ ^[0-9]+$ ]] &&
    [[ "$overlay_start" =~ ^[0-9]+$ ]] &&
    [[ -r "/proc/${overlay_pid}/stat" ]] &&
    [[ -r "/proc/${overlay_pid}/comm" ]] &&
    [[ "$(<"/proc/${overlay_pid}/comm")" =~ ^(\.)?wofi(-wrapped)?$ ]] &&
    [[ "$(awk '{ print $22 }' "/proc/${overlay_pid}/stat")" == "$overlay_start" ]] &&
    kill -0 -- "-$overlay_pid" 2>/dev/null; then
    kill -- "-$overlay_pid"
    exit 0
  fi
  rm -f "$pid_file"
fi

command -v hyprctl >/dev/null 2>&1 || exit 1
command -v jq >/dev/null 2>&1 || exit 1
command -v wofi >/dev/null 2>&1 || exit 1

work_dir="$(mktemp -d "${runtime_dir}/keybinds-overlay.XXXXXX")"
bindings_file="${work_dir}/bindings.tsv"

cleanup() {
  rm -f "$pid_file"
  rm -rf "$work_dir"
}
trap cleanup EXIT
trap 'exit 130' INT TERM

show_menu() {
  local menu_file="$1"
  local menu_prompt="$2"
  local result_file="${work_dir}/selection"

  : >"$result_file"
  setsid wofi \
    --dmenu \
    --insensitive \
    --matching fuzzy \
    --prompt "  ${menu_prompt}" \
    --style "$HOME/.config/waybar/keybinds-overlay.css" \
    --width 720 \
    --height 620 \
    --cache-file /dev/null \
    <"$menu_file" >"$result_file" &

  overlay_pid=$!
  overlay_start="$(awk '{ print $22 }' "/proc/${overlay_pid}/stat")"
  printf '%s %s\n' "$overlay_pid" "$overlay_start" >"$pid_file"
  wait "$overlay_pid" || true
  rm -f "$pid_file"
  menu_choice="$(<"$result_file")"
}

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
    def category:
      (.description | ascii_downcase) as $description
      | if (.key | test("^XF86")) then "System & Media"
        elif (.key | test("Print")) or ($description | test("screenshot|capture")) then "Screenshots"
        elif ($description | test("workspace")) then "Workspaces"
        elif ($description | test("column|layout")) then "Layout"
        elif ($description | test("window|focus|fullscreen|maximized")) then "Windows"
        elif ($description | startswith("open ")) then "Applications"
        else "System & Media"
        end;
    map(select(.has_description and (.description | length > 0)))
    | sort_by(.description)
    | .[]
    | ((modifiers + [pretty_key]) | join(" + ")) as $keys
    | "\(category)\t\($keys)\t\(.description)"
  ' >"$bindings_file"

categories=(
  "󰀻|Applications"
  "󰖲|Windows"
  "󰕮|Layout"
  "󰍹|Workspaces"
  "󰹑|Screenshots"
  "󰒓|System & Media"
)

root_menu_file="${work_dir}/root-menu"
: >"$root_menu_file"

# Keep the six subject headings at the top, then expose every shortcut to
# Wofi's fuzzy matcher. The category prefix gives global results context.
for category_entry in "${categories[@]}"; do
  icon="${category_entry%%|*}"
  category="${category_entry#*|}"
  printf '%s  %s\n' "$icon" "$category" >>"$root_menu_file"
done

for category_entry in "${categories[@]}"; do
  category="${category_entry#*|}"
  awk -F '\t' -v category="$category" '
    $1 == category {
      printf "  %s  ›  %-28s  %s\n", $1, $2, $3
    }
  ' "$bindings_file" >>"$root_menu_file"
done

while true; do
  show_menu "$root_menu_file" "Keyboard shortcuts"
  category_choice="$menu_choice"
  [[ -n "$category_choice" ]] || exit 0

  category=""
  for category_entry in "${categories[@]}"; do
    icon="${category_entry%%|*}"
    candidate="${category_entry#*|}"
    if [[ "$category_choice" == "$icon  $candidate" ]]; then
      category="$candidate"
      break
    fi
  done

  # A global shortcut result carries its category before the › separator.
  if [[ -z "$category" && "$category_choice" == *"  ›  "* ]]; then
    category="${category_choice#  }"
    category="${category%%  ›  *}"
  fi

  [[ -n "$category" ]] || continue

  shortcuts_file="${work_dir}/shortcuts"
  {
    printf '󰁍  Back to categories\n'
    awk -F '\t' -v category="$category" '
      $1 == category {
        printf "%-28s  %s\n", $2, $3
      }
    ' "$bindings_file"
  } >"$shortcuts_file"

  while true; do
    show_menu "$shortcuts_file" "$category"
    shortcut_choice="$menu_choice"
    [[ -n "$shortcut_choice" ]] || exit 0
    [[ "$shortcut_choice" == "󰁍  Back to categories" ]] && break
  done
done
