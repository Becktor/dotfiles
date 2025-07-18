#!/bin/bash
# Script to calculate running average of CPU temperature over last 10 seconds

TEMP_FILE="/tmp/eww_temp_history"

# Get current temperature
current_temp=$(sensors 2>/dev/null | grep -oP 'Package id 0:\s+\+\K[0-9]+' | head -n1)

# If no temperature found, default to 0
if [ -z "$current_temp" ]; then
    current_temp=0
fi

# Initialize file if it doesn't exist
if [ ! -f "$TEMP_FILE" ]; then
    touch "$TEMP_FILE"
fi

# Add current temperature to history
echo "$current_temp" >> "$TEMP_FILE"

# Keep only last 10 readings
tail -n 10 "$TEMP_FILE" > "$TEMP_FILE.tmp" && mv "$TEMP_FILE.tmp" "$TEMP_FILE"

# Calculate average
if [ -s "$TEMP_FILE" ]; then
    avg=$(awk '{ sum += $1; count++ } END { if (count > 0) print int(sum/count); else print 0 }' "$TEMP_FILE")
    echo "$avg"
else
    echo "$current_temp"
fi