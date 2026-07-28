#!/usr/bin/env sh

set -eu

notification_id_file="${XDG_RUNTIME_DIR:-/tmp}/handy-recording-notification-id"
lock_file="${XDG_RUNTIME_DIR:-/tmp}/handy-toggle.lock"

exec 9>"$lock_file"
flock --wait 3 9

is_recording() {
  main_pid="$(systemctl --user show handy.service --property MainPID --value)"

  case "$main_pid" in
    ''|0|*[!0-9]*) return 1 ;;
  esac

  # When Handy records through the system-default device, PipeWire owns the
  # ALSA hardware. Match Handy's running capture node through its client PID.
  if command -v pw-dump >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    if pw-dump 2>/dev/null |
      jq -e --argjson main_pid "$main_pid" '
        [
          .[]
          | select(.type == "PipeWire:Interface:Client")
          | select(.info.props["application.process.id"] == $main_pid)
          | .id
        ] as $handy_clients
        | any(
            .[];
            .type == "PipeWire:Interface:Node"
            and .info.state == "running"
            and .info.props["media.class"] == "Stream/Input/Audio"
            and (
              .info.props["client.id"] as $client_id
              | $handy_clients
              | index($client_id) != null
            )
          )
      ' >/dev/null
    then
      return 0
    fi
  fi

  # Fallback for a directly opened ALSA capture device.
  for status_file in /proc/asound/card*/pcm*c/sub*/status; do
    [ -r "$status_file" ] || continue
    [ "$(sed -n 's/^state: *//p' "$status_file")" = "RUNNING" ] || continue

    owner_pid="$(sed -n 's/^owner_pid *: *//p' "$status_file")"
    [ -r "/proc/$owner_pid/status" ] || continue

    owner_tgid="$(sed -n 's/^Tgid:[[:space:]]*//p' "/proc/$owner_pid/status")"
    [ "$owner_tgid" = "$main_pid" ] && return 0
  done

  return 1
}

notify() {
  summary="$1"
  body="$2"
  timeout="$3"
  replaces_id=0

  if [ -r "$notification_id_file" ]; then
    replaces_id="$(cat "$notification_id_file")"
    case "$replaces_id" in
      ''|*[!0-9]*) replaces_id=0 ;;
    esac
  fi

  result="$(
    busctl --user call \
      org.freedesktop.Notifications \
      /org/freedesktop/Notifications \
      org.freedesktop.Notifications \
      Notify 'susssasa{sv}i' \
      "Handy" "$replaces_id" "audio-input-microphone-symbolic" \
      "$summary" "$body" 0 0 "$timeout"
  )"
  notification_id="${result#u }"

  case "$notification_id" in
    ''|*[!0-9]*) return 1 ;;
  esac

  printf '%s\n' "$notification_id" >"$notification_id_file"
}

if ! systemctl --user is-active --quiet handy.service; then
  notify "Handy is unavailable" "The Handy service is not running." 5000
  exit 1
fi

if is_recording; then
  previous_state=recording
else
  previous_state=idle
fi

if ! handy --toggle-transcription; then
  notify "Handy toggle failed" "Handy did not accept the recording command." 5000
  exit 1
fi

attempts=0
while [ "$attempts" -lt 40 ]; do
  if is_recording; then
    current_state=recording
  else
    current_state=idle
  fi

  [ "$current_state" != "$previous_state" ] && break
  attempts=$((attempts + 1))
  sleep 0.05
done

if [ "$current_state" = "$previous_state" ]; then
  notify "Handy status uncertain" "The recording state did not change." 5000
  exit 1
fi

if [ "$current_state" = recording ]; then
  notify "Recording..." "Press Ctrl+M again to stop." 0
else
  notify "Transcribing..." "Handy is processing your recording." 2000
fi
