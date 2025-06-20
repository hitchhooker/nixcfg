#!/bin/bash
# ~/.config/polybar/scripts/gputemp.sh

temp=$(sensors amdgpu-pci-0400 | grep edge | awk '{print $2}' | sed 's/+//' | sed 's/°C//')
temp_int=${temp%.*}

if [ "$temp_int" -ge 80 ]; then
   echo "%{F#FF0000}${temp}°C%{F-}"
elif [ "$temp_int" -ge 70 ]; then
   echo "%{F#FF6600}${temp}°C%{F-}"
elif [ "$temp_int" -ge 60 ]; then
   echo "%{F#FFAA00}${temp}°C%{F-}"
else
   echo "%{F#00FFE1}${temp}°C%{F-}"
fi
