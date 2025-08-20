#!/usr/bin/env bash

# Terminate already running bar instances
pkill polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

~/.local/bin/btc-polybar &
sleep 1
pkill btc-polybar
# Launch Polybar
polybar top -c ~/.config/polybar/config.ini &
