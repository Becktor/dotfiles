#!/bin/bash

# Get all connected devices
devices=""

if command -v bluetoothctl >/dev/null 2>&1; then
    # Get all connected device lines (excluding Media/Endpoint/Transport)
    while IFS= read -r line; do
        if [[ "$line" =~ ^Device\ [0-9A-Fa-f:]{17}\ .+ ]]; then
            mac=$(echo "$line" | awk '{print $2}')
            name=$(echo "$line" | awk '{for(i=3;i<=NF;i++) printf "%s ", $i}' | sed 's/[[:space:]]*$//')
            
            # Get additional device info
            device_info=""
            device_class=""
            
            # Get device class/icon
            icon_info=$(bluetoothctl info "$mac" 2>/dev/null | grep -i "Icon:" | awk '{print $2}')
            case "$icon_info" in
                "input-keyboard") device_class="⌨️" ;;
                "audio-headphones") device_class="🎧" ;;
                "input-mouse") device_class="🖱️" ;;
                "phone") device_class="📱" ;;
                "computer") device_class="💻" ;;
                *) device_class="🔗" ;;
            esac
            
            # Get battery info from bluetoothctl info
            battery_info=$(bluetoothctl info "$mac" 2>/dev/null | grep -i "Battery Percentage" | awk '{print $4}' | sed 's/[()]//g')
            if [ -n "$battery_info" ]; then
                # Convert hex to decimal if needed
                if [[ "$battery_info" =~ ^0x ]]; then
                    battery_decimal=$(printf "%d" "$battery_info")
                    device_info="${battery_decimal}%"
                else
                    device_info="${battery_info}%"
                fi
            fi
            
            # If no battery info, check if this is AirPods and try BLE scanning with averaging
            if [ -z "$device_info" ] && [[ "$name" =~ [Aa]ir[Pp]od ]]; then
                airpods_info=$(/home/jobe/git/dotfiles/eww/scripts/airpods-battery-average.sh 2>/dev/null)
                if [ $? -eq 0 ] && [ -n "$airpods_info" ]; then
                    status=$(echo "$airpods_info" | jq -r '.status // 0' 2>/dev/null)
                    if [ "$status" = "1" ]; then
                        left=$(echo "$airpods_info" | jq -r '.left // -1' 2>/dev/null)
                        right=$(echo "$airpods_info" | jq -r '.right // -1' 2>/dev/null)
                        case_battery=$(echo "$airpods_info" | jq -r '.case // -1' 2>/dev/null)
                        
                        battery_parts=""
                        if [ "$left" != "-1" ] && [ "$right" != "-1" ]; then
                            battery_parts="L:${left}% R:${right}%"
                        elif [ "$left" != "-1" ]; then
                            battery_parts="L:${left}%"
                        elif [ "$right" != "-1" ]; then
                            battery_parts="R:${right}%"
                        fi
                        
                        if [ "$case_battery" != "-1" ] && [ -n "$battery_parts" ]; then
                            device_info="$battery_parts Case:${case_battery}%"
                        elif [ "$case_battery" != "-1" ]; then
                            device_info="Case:${case_battery}%"
                        elif [ -n "$battery_parts" ]; then
                            device_info="$battery_parts"
                        fi
                    fi
                fi
            fi
            
            # Skip adding "Connected" status - just use battery info if available
            
            # Format the final name with info
            formatted_name="$device_class $name"
            if [ -n "$device_info" ]; then
                formatted_name="$formatted_name ($device_info)"
            fi
            
            if [ -n "$devices" ]; then
                devices="$devices\n$formatted_name"
            else
                devices="$formatted_name"
            fi
        fi
    done <<< "$(bluetoothctl devices Connected)"
fi

if [ -n "$devices" ]; then
    echo -e "$devices"
else
    echo "None"
fi