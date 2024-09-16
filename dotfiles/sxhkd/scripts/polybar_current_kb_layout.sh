#!/bin/bash

export DISPLAY=:0

current_layout=$(setxkbmap -query | awk '/layout:/ {print $2}')
echo "KB: $current_layout"
