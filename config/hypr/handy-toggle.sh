#!/usr/bin/env sh

set -eu

notification_id_file="${XDG_RUNTIME_DIR:-/tmp}/handy-recording-notification-id"
lock_file="${XDG_RUNTIME_DIR:-/tmp}/handy-toggle.lock"

exec 9>"$lock_file"
flock --wait 3 9

handy_main_pid() {
  main_pid="$(systemctl --user show handy.service --property MainPID --value)"

  case "$main_pid" in
    ''|0|*[!0-9]*) ;;
    *)
      [ -r "/proc/$main_pid/status" ] && {
        printf '%s\n' "$main_pid"
        return 0
      }
      ;;
  esac

  # Handy may have been reopened from the app launcher rather than systemd.
  # Accept that instance so Ctrl+M continues to work without starting a duplicate.
  main_pid="$(pgrep -u "$(id -u)" -x 'handy|\.handy-wrapped' 2>/dev/null | head -n 1)"
  case "$main_pid" in
    ''|0|*[!0-9]*) return 1 ;;
    *) printf '%s\n' "$main_pid" ;;
  esac
}

is_recording() {
  main_pid="$(handy_main_pid)" || return 1

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

handy_capture_source() {
  main_pid="$(handy_main_pid)" || return 1

  # Name of the PipeWire source that Handy's capture stream is linked to.
  pw-dump 2>/dev/null |
    jq -er --argjson main_pid "$main_pid" '
      . as $all
      | [
          .[]
          | select(.type == "PipeWire:Interface:Client")
          | select(.info.props["application.process.id"] == $main_pid)
          | .id
        ] as $handy_clients
      | [
          .[]
          | select(.type == "PipeWire:Interface:Node")
          | select(.info.props["media.class"] == "Stream/Input/Audio")
          | select(.info.props["client.id"] as $client_id | $handy_clients | index($client_id) != null)
          | .id
        ] as $handy_nodes
      | [
          .[]
          | select(.type == "PipeWire:Interface:Link")
          | select(.info["input-node-id"] as $node | $handy_nodes | index($node) != null)
          | .info["output-node-id"]
        ][0] as $source_id
      | $all[]
      | select(.id == $source_id)
      | .info.props["node.name"]
    '
}

microphone_is_awake() {
  # WirePlumber keeps the headset capture device open for a while after the
  # last recording (see wireplumber.conf.d). Until it suspends, the headset's
  # microphone link stays on and recording can start without a warm-up.
  source="$(
    wpctl inspect @DEFAULT_AUDIO_SOURCE@ 2>/dev/null |
      sed -n 's/^[ *]*node\.name = "\(.*\)"$/\1/p'
  )"
  [ -n "$source" ] || return 1

  pw-dump 2>/dev/null |
    jq -e --arg source "$source" '
      any(
        .[];
        .type == "PipeWire:Interface:Node"
        and .info.props["node.name"] == $source
        and (.info.state == "idle" or .info.state == "running")
      )
    ' >/dev/null
}

# Seconds the wireless headset needs to wake its microphone link.
microphone_warmup_seconds="${HANDY_MIC_WARMUP_SECONDS:-1.5}"

wait_for_microphone() {
  # Wireless headsets deliver exact digital silence while their microphone
  # link wakes up. Their noise gate also sends silence while you are quiet, so
  # stop at the first non-zero sample or once the warm-up time has passed.
  source="$(handy_capture_source)" || source=""

  timeout "$microphone_warmup_seconds" \
    pw-record --raw --latency 10ms --rate 48000 --channels 1 \
    ${source:+--target "$source"} - 2>/dev/null |
    LC_ALL=C cmp - /dev/zero >/dev/null 2>&1 || true
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

if ! handy_main_pid >/dev/null; then
  systemctl --user start handy.service || true

  attempts=0
  while [ "$attempts" -lt 40 ] && ! handy_main_pid >/dev/null; do
    attempts=$((attempts + 1))
    sleep 0.05
  done

  if ! handy_main_pid >/dev/null; then
    notify "Handy is unavailable" "The Handy service could not be started." 5000
    exit 1
  fi
fi

if is_recording; then
  previous_state=recording
else
  previous_state=idle
fi

if microphone_is_awake; then
  microphone_was_awake=true
else
  microphone_was_awake=false
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

if [ "$current_state" = idle ]; then
  notify "Transcribing..." "Handy is processing your recording." 2000
  exit 0
fi

if [ "$microphone_was_awake" = true ]; then
  notify "Ready - speak now" "Press Ctrl+M again to stop." 0
  exit 0
fi

notify "Waiting for microphone..." "Hold on until it says ready." 0

# Release the lock while waiting so Ctrl+M can stop the recording meanwhile.
exec 9>&-
wait_for_microphone

exec 9>"$lock_file"
flock --wait 3 9

# A second Ctrl+M may have stopped the recording while we were waiting.
is_recording || exit 0

notify "Ready - speak now" "Press Ctrl+M again to stop." 0
