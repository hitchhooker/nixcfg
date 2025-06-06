#!/bin/bash

# Power menu for rofi
if [ -z "$@" ]; then
    echo -en "Lock\0icon\x1fsystem-lock-screen\n"
    echo -en "Logout\0icon\x1fsystem-log-out\n"
    echo -en "Suspend\0icon\x1fsystem-suspend\n"
    echo -en "Reboot\0icon\x1fsystem-reboot\n"
    echo -en "Shutdown\0icon\x1fsystem-shutdown\n"
else
    case "$1" in
        "Lock")
            i3lock-fancy-rapid 5 3 || i3lock -c 000000
            ;;
        "Logout")
            bspc quit || pkill -KILL -u $USER
            ;;
        "Suspend")
            systemctl suspend
            ;;
        "Reboot")
            systemctl reboot
            ;;
        "Shutdown")
            systemctl poweroff
            ;;
    esac
fi
