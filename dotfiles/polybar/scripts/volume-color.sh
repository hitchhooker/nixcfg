#!/bin/sh

# Get volume percentage
vol=$(amixer get Master | grep -o '[0-9]*%' | head -1 | tr -d '%')

# Check if muted
if amixer get Master | grep -q '\[off\]'; then
    echo "%{F#666666}MUTE%{F-}"
    exit 0
fi

# Color based on volume level
if [ "$vol" -ge 80 ]; then
    color="#FF0000"  # Red - too loud
elif [ "$vol" -ge 60 ]; then
    color="#FF6600"  # Orange
elif [ "$vol" -ge 40 ]; then
    color="#FFFF00"  # Yellow
elif [ "$vol" -ge 20 ]; then
    color="#66FF00"  # Light green
else
    color="#00FF00"  # Neon green - quiet
fi

echo "%{F$color}VOL $vol%%{F-}"
