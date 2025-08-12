#!/bin/bash

# Manual Screen Rotation Toggle Script
# Cycles through different screen orientations

MONITOR="eDP-1"
RESOLUTION="1920x1200@60"
STATE_FILE="/tmp/rotation-state"

get_current_rotation() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    else
        echo "0"
    fi
}

set_rotation() {
    local transform="$1"
    local name="$2"
    
    hyprctl keyword monitor "$MONITOR,$RESOLUTION,0x0,1,transform,$transform"
    echo "$transform" > "$STATE_FILE"
    echo "Screen rotated to: $name"
    
    # Send notification if notify-send is available
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Screen Rotation" "Rotated to: $name" -t 2000
    fi
}

case "$1" in
    "normal"|"0")
        set_rotation "0" "Normal (Landscape)"
        ;;
    "right"|"90"|"1")
        set_rotation "1" "90° Right (Portrait)"
        ;;
    "inverted"|"180"|"2")
        set_rotation "2" "180° Inverted"
        ;;
    "left"|"270"|"3")
        set_rotation "3" "270° Left (Portrait)"
        ;;
    "cycle"|"toggle"|"")
        current=$(get_current_rotation)
        case "$current" in
            "0")
                set_rotation "1" "90° Right (Portrait)"
                ;;
            "1")
                set_rotation "2" "180° Inverted"
                ;;
            "2")
                set_rotation "3" "270° Left (Portrait)"
                ;;
            "3"|*)
                set_rotation "0" "Normal (Landscape)"
                ;;
        esac
        ;;
    "status")
        current=$(get_current_rotation)
        case "$current" in
            "0") echo "Normal (Landscape)" ;;
            "1") echo "90° Right (Portrait)" ;;
            "2") echo "180° Inverted" ;;
            "3") echo "270° Left (Portrait)" ;;
            *) echo "Unknown" ;;
        esac
        ;;
    *)
        echo "Usage: $0 [normal|right|inverted|left|cycle|status]"
        echo "  normal/0   - Normal landscape orientation"
        echo "  right/90/1 - 90 degrees clockwise (portrait)"
        echo "  inverted/180/2 - 180 degrees (upside down)"
        echo "  left/270/3 - 270 degrees clockwise (portrait)"
        echo "  cycle/toggle - Cycle through orientations"
        echo "  status     - Show current orientation"
        echo ""
        echo "If no argument is provided, cycles through orientations."
        exit 1
        ;;
esac