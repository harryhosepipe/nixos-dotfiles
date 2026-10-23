#!/usr/bin/env sh
set -eu
script_dir="$(dirname -- "$(readlink -f "$0")")"
exec sh "$script_dir/../dns-switcher/launch.sh" "$@"
