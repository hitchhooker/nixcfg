#!/usr/bin/env bash

# Terminate already running bar instances
pkill polybar

# Wait until the processes have been shut down
sleep 2
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch Polybar
polybar top -c ~/.config/polybar/config.ini &
