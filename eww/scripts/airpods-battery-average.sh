#!/bin/bash

# Configuration
HISTORY_FILE="/tmp/airpods_battery_history"
MAX_HISTORY=5  # Number of readings to average
MAX_AGE=30     # Maximum age in seconds for a reading to be considered valid

# Function to get current timestamp
get_timestamp() {
    date +%s
}

# Function to clean old entries
clean_old_entries() {
    local current_time=$(get_timestamp)
    local temp_file=$(mktemp)
    
    if [ -f "$HISTORY_FILE" ]; then
        while IFS='|' read -r timestamp left right case_battery; do
            if [ $((current_time - timestamp)) -le $MAX_AGE ]; then
                echo "$timestamp|$left|$right|$case_battery" >> "$temp_file"
            fi
        done < "$HISTORY_FILE"
        mv "$temp_file" "$HISTORY_FILE"
    fi
}

# Function to calculate average
calculate_average() {
    local values="$1"
    local count=0
    local sum=0
    
    for value in $values; do
        # Convert value to integer, default to 0 if not a number
        local int_value=$(echo "$value" | awk '{print int($1)}' 2>/dev/null || echo "0")
        if [ "$int_value" != "-1" ] && [ "$int_value" -gt 0 ]; then
            sum=$((sum + int_value))
            count=$((count + 1))
        fi
    done
    
    if [ $count -gt 0 ]; then
        echo $((sum / count))
    else
        echo "-1"
    fi
}

# Get current battery reading
current_reading=$(python3 /home/jobe/git/dotfiles/eww/scripts/airpods-battery.py 2>/dev/null)

if [ $? -eq 0 ] && [ -n "$current_reading" ]; then
    status=$(echo "$current_reading" | jq -r '.status // 0' 2>/dev/null)
    
    if [ "$status" = "1" ]; then
        left=$(echo "$current_reading" | jq -r '.charge.left // -1' 2>/dev/null)
        right=$(echo "$current_reading" | jq -r '.charge.right // -1' 2>/dev/null)
        case_battery=$(echo "$current_reading" | jq -r '.charge.case // -1' 2>/dev/null)
        
        # Clean old entries
        clean_old_entries
        
        # Add current reading if we got valid data
        if [ "$left" != "-1" ] || [ "$right" != "-1" ] || [ "$case_battery" != "-1" ]; then
            current_time=$(get_timestamp)
            echo "$current_time|$left|$right|$case_battery" >> "$HISTORY_FILE"
        fi
        
        # Keep only last MAX_HISTORY entries
        if [ -f "$HISTORY_FILE" ]; then
            tail -n $MAX_HISTORY "$HISTORY_FILE" > "${HISTORY_FILE}.tmp"
            mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"
        fi
        
        # Calculate averages
        left_values=""
        right_values=""
        case_values=""
        
        if [ -f "$HISTORY_FILE" ]; then
            while IFS='|' read -r timestamp left_val right_val case_val; do
                left_values="$left_values $left_val"
                right_values="$right_values $right_val"
                case_values="$case_values $case_val"
            done < "$HISTORY_FILE"
            
            avg_left=$(calculate_average "$left_values")
            avg_right=$(calculate_average "$right_values")
            avg_case=$(calculate_average "$case_values")
            
            # Output averaged result
            echo "$current_reading" | jq --argjson avg_left "$avg_left" --argjson avg_right "$avg_right" --argjson avg_case "$avg_case" \
                '.charge.left = $avg_left | .charge.right = $avg_right | .charge.case = $avg_case'
        else
            echo "$current_reading"
        fi
    else
        echo "$current_reading"
    fi
else
    echo '{"status": 0, "error": "No data"}'
fi