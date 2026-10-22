#!/usr/bin/env sh
set -eu

script_path="$(readlink -f "$0")"
exec "$(dirname "$script_path")/../audio-popup/toggle.sh"
