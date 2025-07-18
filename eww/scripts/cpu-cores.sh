#!/bin/bash
# Get per-core CPU usage

# Function to get CPU usage for a specific core
get_cpu_usage() {
    local cpu=$1
    local prev_file="/tmp/cpu_stats_$cpu"
    
    # Read current stats
    local stats=$(grep "^cpu$cpu " /proc/stat)
    local user=$(echo $stats | awk '{print $2}')
    local nice=$(echo $stats | awk '{print $3}')
    local system=$(echo $stats | awk '{print $4}')
    local idle=$(echo $stats | awk '{print $5}')
    local iowait=$(echo $stats | awk '{print $6}')
    local irq=$(echo $stats | awk '{print $7}')
    local softirq=$(echo $stats | awk '{print $8}')
    
    local total=$((user + nice + system + idle + iowait + irq + softirq))
    local active=$((user + nice + system + irq + softirq))
    
    # Read previous stats
    if [ -f "$prev_file" ]; then
        local prev_total=$(cat "$prev_file" | cut -d' ' -f1)
        local prev_active=$(cat "$prev_file" | cut -d' ' -f2)
        
        local diff_total=$((total - prev_total))
        local diff_active=$((active - prev_active))
        
        if [ $diff_total -gt 0 ]; then
            local usage=$((100 * diff_active / diff_total))
            echo $usage
        else
            echo 0
        fi
    else
        echo 0
    fi
    
    # Save current stats
    echo "$total $active" > "$prev_file"
}

# Output format: JSON array of objects with core type and usage
echo -n '['

# Performance cores (0-9) - Physical cores 0-8
for i in {0..9}; do
    usage=$(get_cpu_usage $i)
    echo -n "{\"core\":$i,\"type\":\"P\",\"usage\":$usage}"
    if [ $i -lt 13 ]; then echo -n ","; fi
done

# Efficiency cores (10-13) - Physical cores 9-11
for i in {10..13}; do
    usage=$(get_cpu_usage $i)
    echo -n "{\"core\":$i,\"type\":\"E\",\"usage\":$usage}"
    if [ $i -lt 13 ]; then echo -n ","; fi
done

echo ']'