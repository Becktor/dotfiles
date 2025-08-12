#!/bin/bash

# Create JSON array of bluetooth devices for table display
devices_json="["

first_device=true

if command -v bluetoothctl >/dev/null 2>&1; then
    while IFS= read -r line; do
        if [[ "$line" =~ ^Device\ [0-9A-Fa-f:]{17}\ .+ ]]; then
            mac=$(echo "$line" | awk '{print $2}')
            name=$(echo "$line" | awk '{for(i=3;i<=NF;i++) printf "%s ", $i}' | sed 's/[[:space:]]*$//')
            
            # Get device class/icon
            icon_info=$(bluetoothctl info "$mac" 2>/dev/null | grep -i "Icon:" | awk '{print $2}')
            case "$icon_info" in
                "input-keyboard") device_icon="⌨️" ;;
                "audio-headphones") device_icon="🎧" ;;
                "input-mouse") device_icon="🖱️" ;;
                "phone") device_icon="📱" ;;
                "computer") device_icon="💻" ;;
                *) device_icon="🔗" ;;
            esac
            
            # Get battery info from bluetoothctl info
            battery_info=$(bluetoothctl info "$mac" 2>/dev/null | grep -i "Battery Percentage" | awk '{print $4}' | sed 's/[()]//g')
            battery_level=""
            if [ -n "$battery_info" ]; then
                # Convert hex to decimal if needed
                if [[ "$battery_info" =~ ^0x ]]; then
                    battery_decimal=$(printf "%d" "$battery_info")
                    battery_level="$battery_decimal%"
                else
                    battery_level="$battery_info%"
                fi
            fi
            
            # If battery_level is still empty, set a default
            if [ -z "$battery_level" ]; then
                battery_level="N/A"
            fi
            
            # Add device to JSON
            if [ "$first_device" = true ]; then
                first_device=false
            else
                devices_json="$devices_json,"
            fi
            
            devices_json="$devices_json{\"icon\":\"$device_icon\",\"name\":\"$name\",\"battery\":\"$battery_level\"}"
        fi
    done <<< "$(bluetoothctl devices)"
fi

devices_json="$devices_json]"
echo "$devices_json"