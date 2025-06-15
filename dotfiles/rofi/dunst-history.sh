#!/usr/bin/env bash
[[ "$@" == "quit" ]] && exit 0
h=$(dunstctl history)
[[ -z "$h" || "$h" == "[]" ]] && { echo -en "\0prompt\x1fNo notifications\n\0message\x1fHistory is empty\n"; exit 0; }
if [[ -z "$@" ]]; then
    echo -en "\0prompt\x1fNotifications\n"
    echo "$h" | jq -r '.data[0][]|@base64' | while read n; do
        j() { echo "$n" | base64 -d | jq -r "$1"; }
        u=$(j '.urgency.data'); a=$(j '.appname.data'); s=$(j '.summary.data'); b=$(j '.body.data')
        i=$([[ $u == 2 ]] && echo 🚨 || ([[ $u == 1 ]] && echo ⚡ || echo ℹ️))
        echo -en "$i ${a:+[$a] }$s\0info\x1f$b\n"
    done | head -50
else
    dunstify "History" "$(echo "$@" | sed 's/^[^ ]* //')" -t 3000
fi
