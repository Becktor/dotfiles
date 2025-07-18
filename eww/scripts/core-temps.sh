#!/bin/bash
# Get per-core CPU temperatures from sensors

# Initialize array with default temps for all 14 logical cores
declare -a temps=(50 50 50 50 50 50 50 50 50 50 50 50 50 50)

# Get sensor data and process line by line
sensors_data=$(sensors | grep "Core")

# Extract temperatures using sed and process mapping
while read -r line; do
    if [[ -n "$line" ]]; then
        # Extract core number and temperature
        core_num=$(echo "$line" | sed 's/Core \([0-9]*\):.*/\1/')
        temp=$(echo "$line" | awk '{print $3}' | sed 's/+//' | sed 's/°C//' | cut -d'.' -f1)
        
        # Map physical cores to logical cores based on Intel topology
        case $core_num in
            0) temps[0]=$temp; temps[1]=$temp ;;
            1) temps[2]=$temp; temps[3]=$temp ;;
            2) temps[4]=$temp; temps[5]=$temp ;;
            3) temps[6]=$temp; temps[7]=$temp ;;
            4) temps[8]=$temp; temps[9]=$temp ;;
            5) temps[10]=$temp ;;
            6) temps[11]=$temp ;;
            7) temps[12]=$temp ;;
            8) temps[13]=$temp ;;
            12) temps[10]=$temp ;;
            32) temps[12]=$temp ;;
            33) temps[13]=$temp ;;
        esac
    fi
done <<< "$sensors_data"

# Output in array format for eww
echo -n "["
for i in {0..13}; do
    echo -n "${temps[$i]}"
    if [ $i -lt 13 ]; then echo -n ","; fi
done
echo "]"