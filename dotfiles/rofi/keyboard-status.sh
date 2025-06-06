#!/usr/bin/env bash
# Show current keyboard layout status

# Get current layout
current_layout=$(setxkbmap -query | grep 'layout:' | awk '{print $2}' | cut -d',' -f1)

# Show notification with current layout
case "$current_layout" in
    "us")
        dunstify -r 8888 -t 1500 "Keyboard Layout" "🇺🇸 English (US)" -i input-keyboard
        ;;
    "fi")
        dunstify -r 8888 -t 1500 "Keyboard Layout" "🇫🇮 Finnish" -i input-keyboard
        ;;
    *)
        dunstify -r 8888 -t 1500 "Keyboard Layout" "$current_layout" -i input-keyboard
        ;;
esac
