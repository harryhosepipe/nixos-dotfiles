#!/usr/bin/env sh

# Waybar reads this JSON and renders the colored VOL text.
# The color moves from normal text, to LAN green, to bright red.
wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '
function clamp(value, low, high) {
  if (value < low) return low
  if (value > high) return high
  return value
}

function hex_to_dec(pair) {
  return index("0123456789abcdef", substr(pair, 1, 1)) * 16 + index("0123456789abcdef", substr(pair, 2, 1)) - 17
}

function channel_at(start_hex, end_hex, ratio) {
  return int(hex_to_dec(start_hex) + (hex_to_dec(end_hex) - hex_to_dec(start_hex)) * ratio + 0.5)
}

function blend(start_color, end_color, ratio) {
  ratio = clamp(ratio, 0, 1)
  r = channel_at(substr(start_color, 2, 2), substr(end_color, 2, 2), ratio)
  g = channel_at(substr(start_color, 4, 2), substr(end_color, 4, 2), ratio)
  b = channel_at(substr(start_color, 6, 2), substr(end_color, 6, 2), ratio)
  return sprintf("#%02x%02x%02x", r, g, b)
}

{
  volume = int($2 * 100 + 0.5)
  volume = clamp(volume, 0, 100)

  if ($0 ~ /MUTED/) {
    text = "MUTED"
    color = "#444444"
  } else {
    text = sprintf("VOL %d%%", volume)

    if (volume <= 50) {
      color = blend("#444444", "#083613", volume / 50)
    } else {
      color = blend("#083613", "#ff2b2b", (volume - 50) / 50)
    }
  }

  printf("{\"text\":\"<span foreground=\\\"%s\\\">%s</span>\",\"tooltip\":\"%s\",\"percentage\":%d}\n", color, text, text, volume)
}
'
