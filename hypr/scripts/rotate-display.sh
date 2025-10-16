#!/bin/bash

# Get current monitor and transform
MONITOR=$(hyprctl monitors -j | jq -r '.[0].name')
CURRENT=$(hyprctl monitors -j | jq -r '.[0].transform')
NEXT=$(( (CURRENT + 1) % 4 ))

# Rotate the monitor
hyprctl keyword monitor "$MONITOR,preferred,auto,1,transform,$NEXT"

# Try to set touch device transform (Hyprland should handle this automatically, but we try anyway)
TOUCH_DEVICE="ilit2901:00-222a:5539"
hyprctl keyword "device[$TOUCH_DEVICE]:transform" "$NEXT" 2>/dev/null

# Alternative: bind touch device to the monitor output
hyprctl keyword "device[$TOUCH_DEVICE]:output" "$MONITOR" 2>/dev/null
