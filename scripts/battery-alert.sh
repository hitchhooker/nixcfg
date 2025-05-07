#!/bin/bash

# Constants
readonly BATTERY_PATH="/sys/class/power_supply/BAT0/capacity"
readonly AC_ADAPTER_PATHS=(
  "/sys/class/power_supply/ACAD/online"
  "/sys/class/power_supply/AC/online"
  "/sys/class/power_supply/ADP1/online"
)
readonly CRITICAL_BATTERY_THRESHOLD=25
readonly LOW_BRIGHTNESS=0.2
readonly HIGH_BRIGHTNESS=0.8
readonly FLASH_DELAY=0.5
readonly FLASH_COUNT=5

# Get battery status
battery_percentage=$(cat "$BATTERY_PATH")

# Check charging status across possible adapter paths
charging=0
for adapter in "${AC_ADAPTER_PATHS[@]}"; do
  if [ -f "$adapter" ] && [ "$(cat "$adapter" 2>/dev/null)" -eq 1 ]; then
    charging=1
    break
  fi
done

# Debug output
echo "battery $battery_percentage%"
if [ "$charging" -eq 1 ]; then
  echo "charging"
else
  echo "not charging"
fi

# Critical battery handling
if [ "$battery_percentage" -le "$CRITICAL_BATTERY_THRESHOLD" ] && [ "$charging" -eq 0 ]; then
  # Save current brightness
  current_brightness=$(xrandr --verbose | grep -i brightness | head -n 1 | awk '{print $2}')
  
  # Get current display output
  display_output=$(xrandr | grep " connected" | cut -f1 -d" ")
  
  # Flash screen to alert user
  for ((i=1; i<=FLASH_COUNT; i++)); do
    xrandr --output "$display_output" --brightness "$LOW_BRIGHTNESS"
    sleep "$FLASH_DELAY"
    xrandr --output "$display_output" --brightness "$HIGH_BRIGHTNESS"
    sleep "$FLASH_DELAY"
  done
  
  # Restore original brightness
  xrandr --output "$display_output" --brightness "$current_brightness"
  
  # Send system notification
  DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus \
    notify-send -u critical "BATTERY CRITICAL" "Battery level below $CRITICAL_BATTERY_THRESHOLD%! Connect charger immediately."
fi
