#!/usr/bin/env bash
# Dunst notification history viewer for rofi

# Get dunst history
history=$(dunstctl history)

# Check if history is empty
if [[ -z "$history" ]] || [[ "$history" == "[]" ]]; then
    if [[ -z "$@" ]]; then
        echo -en "No notifications in history\0icon\x1fdialog-information\n"
    fi
    exit 0
fi

# If no argument, parse and display history
if [[ -z "$@" ]]; then
    # Parse JSON and format for rofi
    echo "$history" | jq -r '.data[] | 
        # Build the display string
        if .urgency.data == 0 then "ℹ️" 
        elif .urgency.data == 1 then "⚡" 
        else "🚨" end + " " +
        
        # Add app name if available
        if .appname.data != "" then "[" + .appname.data + "] " else "" end +
        
        # Add summary
        .summary.data +
        
        # Add separator and index for rofi metadata
        "\0info\x1f" + 
        
        # Add body as info (rofi will show in smaller text)
        if .body.data != "" then .body.data else "No details" end +
        
        # Add icon if available
        if .icon.data != "" then "\x1ficon\x1f" + .icon.data else "" end
    ' | head -50  # Limit to 50 most recent
else
    # When item is selected, show detailed view
    selected_index=$(echo "$@" | grep -oE '\[[0-9]+\]' | tr -d '[]')
    
    # You could add actions here like:
    # - Copy to clipboard
    # - Re-display the notification
    # - Open associated app
    
    # For now, just show it was selected
    notify-send "Notification History" "Selected: $@" -t 2000
fi
