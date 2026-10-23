#!/usr/bin/env sh
set -eu

# Prefer the declared package after the next normal Home Manager activation.
if command -v dns-switcher >/dev/null 2>&1; then
  exec dns-switcher "$@"
fi

# An existing local GTK runtime can be registered without evaluating/building Nix.
runtime="${XDG_STATE_HOME:-$HOME/.local/state}/dns-switcher/runtime.sh"
if [ -r "$runtime" ]; then
  . "$runtime"
fi
script_dir="$(dirname -- "$(readlink -f "$0")")"
export GDK_BACKEND=wayland
export PYTHONDONTWRITEBYTECODE=1
if ! "${DNS_SWITCHER_PYTHON:-python3}" -c 'import gi; gi.require_version("Gtk", "4.0")' 2>/dev/null; then
  message='The DNS app needs its GTK runtime. Activate your Home Manager configuration to install it.'
  command -v notify-send >/dev/null 2>&1 && notify-send 'DNS switcher' "$message"
  printf '%s\n' "$message" >&2
  exit 1
fi
exec "${DNS_SWITCHER_PYTHON:-python3}" "$script_dir/app.py" "$@"
