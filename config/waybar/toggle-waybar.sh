#!/usr/bin/env sh

# Use Waybar's own hide/show signal when the bar is already running.
# Some Nix builds show the process as `waybar`, others as `.waybar-wrapped`.
if pgrep -x waybar >/dev/null 2>&1 || pgrep -x .waybar-wrapped >/dev/null 2>&1; then
  pkill -SIGUSR1 -x waybar
  pkill -SIGUSR1 -x .waybar-wrapped
else
  nohup waybar >/tmp/waybar.log 2>&1 &
fi
