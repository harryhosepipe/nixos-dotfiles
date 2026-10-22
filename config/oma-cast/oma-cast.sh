#!/usr/bin/env bash
set -euo pipefail

ipc() {
  "$OMA_CAST_QUICKSHELL" ipc -p "$OMA_CAST_SHELL" call oma-cast "$@"
}

start() {
  # The greetd session starts Hyprland directly, without a UWSM environment.
  systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE
  systemctl --user start oma-cast.service
}

ready() {
  if [[ $(ipc ping 2>/dev/null) == ok ]]; then return; fi
  start
  for ((attempt = 0; attempt < 50; attempt++)); do
    if [[ $(ipc ping 2>/dev/null) == ok ]]; then return; fi
    sleep 0.1
  done
  echo 'oma-cast did not start; check journalctl --user -u oma-cast.service' >&2
  return 1
}

case "${1:-toggle}" in
  daemon) exec "$OMA_CAST_QUICKSHELL" -p "$OMA_CAST_SHELL" ;;
  start) start ;;
  toggle|show|hide|ping)
    ready
    ipc "${1:-toggle}"
    ;;
  run)
    [[ $# == 2 ]] || { echo 'Usage: oma-cast run <commandId>' >&2; exit 2; }
    ready
    ipc run "$2"
    ;;
  call)
    [[ $# -ge 2 && $# -le 3 ]] || { echo 'Usage: oma-cast call <method> [json]' >&2; exit 2; }
    ready
    payload='{}'
    if [[ $# == 3 ]]; then payload=$3; fi
    ipc call "$2" "$payload"
    ;;
  doctor)
    ready
    ipc call system.healthPing '{}'
    ;;
  *)
    echo 'Usage: oma-cast [toggle|show|hide|ping|start|doctor|run <id>|call <method> [json]]' >&2
    exit 2
    ;;
esac
