#!/usr/bin/env sh
set -eu

script_dir="$(CDPATH='' cd -- "$(dirname -- "$(readlink -f "$0")")" && pwd)"
app="$script_dir/app.tsx"
state_dir="${XDG_RUNTIME_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}}/audio-popup"
mkdir -p "$state_dir"
chmod 700 "$state_dir"
logfile="$state_dir/app.log"

# Serialize rapid shortcut presses while the first instance is starting.
exec 9>"$state_dir/launch.lock"
flock 9

# Resolve the fallback once per login; subsequent opens avoid Nix evaluation.
if ! command -v ags >/dev/null 2>&1 || ! command -v pactl >/dev/null 2>&1; then
  runtime_path="$(cat "$state_dir/runtime-path" 2>/dev/null || true)"
  if ! PATH="$runtime_path:$PATH" command -v ags >/dev/null 2>&1 ||
     ! PATH="$runtime_path:$PATH" command -v pactl >/dev/null 2>&1; then
    # Expand command paths inside the Nix shell, where both tools are available.
    # shellcheck disable=SC2016
    runtime_path="$(nix shell nixpkgs#ags nixpkgs#pulseaudio -c sh -c 'printf "%s:%s" "$(dirname "$(command -v ags)")" "$(dirname "$(command -v pactl)")"')"
    printf '%s\n' "$runtime_path" > "$state_dir/runtime-path"
  fi
  PATH="$runtime_path:$PATH"
  export PATH
fi

# Keep the process warm, but reload automatically after a source/style edit.
signature="$(cksum "$app" "$script_dir/style.scss" "$script_dir/toggle.sh")"
previous="$(cat "$state_dir/source-signature" 2>/dev/null || true)"
if [ "$signature" = "$previous" ] &&
   [ "$(ags request -i audio-popup toggle 2>/dev/null || true)" = "ok" ]; then
  exit 0
fi

ags quit -i audio-popup >/dev/null 2>&1 || true
nohup ags run "$app" >"$logfile" 2>&1 9>&- &
popup_pid=$!
attempt=0
while [ "$attempt" -lt 100 ]; do
  if [ "$(ags request -i audio-popup health 2>/dev/null || true)" = "ready" ]; then
    printf '%s\n' "$signature" > "$state_dir/source-signature"
    exit 0
  fi
  kill -0 "$popup_pid" 2>/dev/null || break
  attempt=$((attempt + 1))
  sleep 0.05
done
printf 'Audio popup failed to start. See %s\n' "$logfile" >&2
exit 1
