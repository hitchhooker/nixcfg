#!/bin/bash
# ~/.config/polybar/scripts/cputemp.sh

temp=$(sensors k10temp-pci-00c3 | grep Tctl | awk '{print $2}' | sed 's/+//' | sed 's/°C//')
temp_int=${temp%.*}

if [ "$temp_int" -ge 85 ]; then
   echo "%{F#FF0000}${temp}°C%{F-}"
elif [ "$temp_int" -ge 75 ]; then
   echo "%{F#FF6600}${temp}°C%{F-}"
elif [ "$temp_int" -ge 65 ]; then
   echo "%{F#FFAA00}${temp}°C%{F-}"
else
   echo "%{F#00FFE1}${temp}°C%{F-}"
fi
