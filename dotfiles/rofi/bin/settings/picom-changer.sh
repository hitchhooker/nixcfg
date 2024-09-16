#!/bin/bash

if [ "$@" == "none" ] || [ "$@" == "clear" ] || [ "$@" == "blur" ]; then
    ~/.config/picom/changer.sh "$@"
else
    echo -e "none\nclear\nblur"
fi
