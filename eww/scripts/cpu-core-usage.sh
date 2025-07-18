#!/bin/bash
# Get per-core CPU usage by reading /proc/stat

# Function to calculate CPU usage
get_cpu_usage() {
    local cpu=$1
    local prev_file="/tmp/cpu_prev_${cpu}"
    
    # Read current stats
    if [ "$cpu" = "all" ]; then
        local line=$(head -1 /proc/stat)
    else
        local line=$(grep "^cpu${cpu} " /proc/stat)
    fi
    
    if [ -z "$line" ]; then
        echo "0"
        return
    fi
    
    # Parse CPU times
    local user=$(echo $line | awk '{print $2}')
    local nice=$(echo $line | awk '{print $3}')
    local system=$(echo $line | awk '{print $4}')
    local idle=$(echo $line | awk '{print $5}')
    local iowait=$(echo $line | awk '{print $6}')
    local irq=$(echo $line | awk '{print $7}')
    local softirq=$(echo $line | awk '{print $8}')
    
    # Calculate totals
    local total=$((user + nice + system + idle + iowait + irq + softirq))
    local active=$((total - idle - iowait))
    
    # Read previous values
    if [ -f "$prev_file" ]; then
        local prev_total=$(cut -d' ' -f1 "$prev_file")
        local prev_active=$(cut -d' ' -f2 "$prev_file")
        
        # Calculate usage
        local delta_total=$((total - prev_total))
        local delta_active=$((active - prev_active))
        
        if [ $delta_total -gt 0 ]; then
            local usage=$((100 * delta_active / delta_total))
            echo $usage
        else
            echo 0
        fi
    else
        echo 0
    fi
    
    # Save current values
    echo "$total $active" > "$prev_file"
}

# Output array format for eww
echo -n "["
for i in {0..13}; do
    usage=$(get_cpu_usage $i)
    echo -n "$usage"
    if [ $i -lt 13 ]; then echo -n ","; fi
done
echo "]"