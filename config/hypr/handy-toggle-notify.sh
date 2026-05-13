#!/usr/bin/env sh

set -eu

state_file="${XDG_RUNTIME_DIR:-/tmp}/handy-recording"
notification_id_file="${XDG_RUNTIME_DIR:-/tmp}/handy-recording-notification-id"
notification_id=7351

notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -a Handy -r "$notification_id" -u "$3" -t "$4" "$1" "$2"
  fi
}

notify_recording() {
  (
    sleep 0.5

    if [ -f "$state_file" ] && command -v notify-send >/dev/null 2>&1; then
      notify-send -p -a Handy -r "$notification_id" -u normal -t 60000 \
        "Recording..." "Press Ctrl+M again to stop." >"$notification_id_file" || true
    fi
  ) &
}

close_recording_notification() {
  if [ ! -f "$notification_id_file" ] || ! command -v busctl >/dev/null 2>&1; then
    return 0
  fi

  id="$(cat "$notification_id_file")"
  rm -f "$notification_id_file"

  case "$id" in
    ''|*[!0-9]*) return 0 ;;
  esac

  busctl --user call \
    org.freedesktop.Notifications \
    /org/freedesktop/Notifications \
    org.freedesktop.Notifications \
    CloseNotification u "$id" >/dev/null 2>&1 || true
}

if [ -f "$state_file" ]; then
  rm -f "$state_file"
  close_recording_notification
  notify "Transcribing..." "Handy is processing your recording." low 2000
  handy --toggle-transcription
else
  touch "$state_file"
  notify_recording

  if ! handy --toggle-transcription; then
    rm -f "$state_file"
    close_recording_notification
    notify "Recording failed" "Handy could not start recording." normal 4000
    exit 1
  fi
fi
