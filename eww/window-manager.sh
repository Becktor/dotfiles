#!/bin/bash

# Window Manager Service for Waybar/EWW Panel Switching
# This service monitors window state and switches between waybar and eww panel

# Configuration
EWW_BINARY="/home/jobe/.local/bin/eww"
WAYBAR_BINARY="/usr/bin/waybar"
WAYBAR_CONFIG="/home/jobe/git/dotfiles/waybar/config"
WAYBAR_STYLE="/home/jobe/git/dotfiles/waybar/style.css"
CHECK_INTERVAL=0.1
USE_EVENTS=true

# State tracking
current_state=""
waybar_pid=""
eww_daemon_pid=""

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >&2
}

# Function to get monitor activity (count of non-floating windows on active workspace per monitor)
get_monitor_activity() {
    # Get active workspace per monitor
    local monitor_workspaces=$(hyprctl monitors -j | jq -r '.[] | "\(.id):\(.activeWorkspace.id)"')
    
    # For each monitor, count windows on its active workspace
    echo "$monitor_workspaces" | while IFS=: read monitor_id workspace_id; do
        local window_count=$(hyprctl clients -j | jq -r --arg ws "$workspace_id" --arg mon "$monitor_id" '.[] | select(.workspace.id == ($ws | tonumber)) | select(.monitor == ($mon | tonumber)) | select(.floating == false) | select(.class | test("^(eww-|waybar)") | not)' | jq -s length)
        if [ "$window_count" -gt 0 ]; then
            echo "$monitor_id:$window_count"
        fi
    done
}

# Function to determine best monitor for EWW panel (only if completely empty)
get_target_monitor() {
    local activity_data=$(get_monitor_activity)
    
    # Get monitor info: id -> name mapping
    local monitor_info=$(hyprctl monitors -j | jq -r '.[] | "\(.id):\(.name)"')
    
    # Priority: external monitor first (id 1), then laptop (id 0)
    local external_monitor_id="1"
    local laptop_monitor_id="0"
    
    # Check external monitor first (monitor id 1) - ONLY if completely empty
    local external_count=$(echo "$activity_data" | grep "^$external_monitor_id:" | cut -d: -f2)
    if [ -z "$external_count" ] && echo "$monitor_info" | grep -q "^$external_monitor_id:"; then
        # External monitor is completely empty (no entry in activity data), get its name
        local external_name=$(echo "$monitor_info" | grep "^$external_monitor_id:" | cut -d: -f2)
        if [ -n "$external_name" ]; then
            echo "$external_name"
            return
        fi
    fi
    
    # Check laptop monitor (monitor id 0) - ONLY if completely empty
    local laptop_count=$(echo "$activity_data" | grep "^$laptop_monitor_id:" | cut -d: -f2)
    if [ -z "$laptop_count" ] && echo "$monitor_info" | grep -q "^$laptop_monitor_id:"; then
        # Laptop monitor is completely empty (no entry in activity data), get its name
        local laptop_name=$(echo "$monitor_info" | grep "^$laptop_monitor_id:" | cut -d: -f2)
        if [ -n "$laptop_name" ]; then
            echo "$laptop_name"
            return
        fi
    fi
    
    # No completely empty monitor found - return nothing (don't show EWW panel)
    echo ""
}

# Function to check if there are active windows (for waybar logic)
has_active_windows() {
    local active_window=$(hyprctl activewindow -j 2>/dev/null)
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    local window_class=$(echo "$active_window" | jq -r '.class // ""')
    local window_title=$(echo "$active_window" | jq -r '.title // ""')
    
    # Consider desktop empty if no class or if it's just the desktop
    if [ -z "$window_class" ] || [ "$window_class" = "null" ] || [ "$window_class" = "" ]; then
        return 1
    fi
    
    # Exclude certain window classes that shouldn't trigger waybar
    case "$window_class" in
        "eww-"*|"waybar"|"")
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

# Function to show waybar
show_waybar() {
    # Start waybar if not running
    if ! pgrep -f "waybar" >/dev/null; then
        log "Starting waybar..."
        $WAYBAR_BINARY -c "$WAYBAR_CONFIG" -s "$WAYBAR_STYLE" &
        waybar_pid=$!
        sleep 0.2
    else
        # Resume waybar if it was stopped
        pkill -CONT waybar 2>/dev/null || true
    fi
}

# Function to hide waybar
hide_waybar() {
    if pgrep -f "waybar" >/dev/null; then
        log "Hiding waybar..."
        pkill -TERM waybar 2>/dev/null
    fi
}

# Function to show eww panel
show_eww_panel() {
    # Start eww daemon if not running
    if ! pgrep -f "eww.*daemon" >/dev/null; then
        log "Starting eww daemon..."
        $EWW_BINARY daemon &
        eww_daemon_pid=$!
        sleep 0.5
    fi
    
    # Determine target monitor
    local target_monitor=$(get_target_monitor)
    if [ -z "$target_monitor" ]; then
        log "No completely empty monitor found - not showing EWW panel"
        hide_eww_panel
        return
    fi
    
    log "Target monitor for EWW panel: $target_monitor"
    
    # Close panel if it's open on wrong monitor, then open on correct monitor
    if $EWW_BINARY active-windows 2>/dev/null | grep -q "panel:"; then
        local current_monitor=$($EWW_BINARY active-windows 2>/dev/null | grep "panel:" | cut -d: -f2)
        if [ "$current_monitor" != "$target_monitor" ]; then
            log "Moving eww panel from $current_monitor to $target_monitor..."
            $EWW_BINARY close panel
            sleep 0.1
        fi
    fi
    
    # Open panel if not already open
    if ! $EWW_BINARY active-windows 2>/dev/null | grep -q "panel:"; then
        log "Opening eww panel on $target_monitor..."
        $EWW_BINARY open panel --screen "$target_monitor"
    fi
}

# Function to hide eww panel
hide_eww_panel() {
    if $EWW_BINARY active-windows 2>/dev/null | grep -q "panel:"; then
        log "Closing eww panel..."
        $EWW_BINARY close panel
    fi
}

# Function to cleanup on exit
cleanup() {
    log "Cleaning up..."
    hide_eww_panel
    
    exit 0
}

# Set up signal handlers
trap cleanup EXIT INT TERM

# Function to check and switch UI
check_and_switch() {
    # Always ensure waybar is running
    if ! pgrep -f "waybar" >/dev/null; then
        log "Starting waybar..."
        show_waybar
    fi
    
    # Check if there's at least one completely empty monitor
    local activity_data=$(get_monitor_activity)
    local has_empty_monitor=false
    
    # Check if there's at least one monitor with 0 windows
    if [ -z "$activity_data" ]; then
        has_empty_monitor=true
    else
        # Check each monitor for 0 windows
        local monitor_info=$(hyprctl monitors -j | jq -r '.[].id')
        for monitor_id in $monitor_info; do
            local count=$(echo "$activity_data" | grep "^$monitor_id:" | cut -d: -f2)
            if [ -z "$count" ]; then
                has_empty_monitor=true
                break
            fi
        done
    fi
    
    if [ "$has_empty_monitor" = "true" ]; then
        # At least one monitor is completely empty - show EWW panel on empty monitor
        if [ "$current_state" != "both" ]; then
            log "Empty monitor detected - showing EWW panel on empty monitor"
            show_eww_panel
            current_state="both"
        fi
    else
        # All monitors have windows - hide EWW panel, keep waybar
        if [ "$current_state" != "waybar" ]; then
            log "All monitors have windows - hiding EWW panel"
            hide_eww_panel
            current_state="waybar"
        fi
    fi
}

# Signal handler for interrupting sleep
wakeup_handler() {
    # This signal handler will interrupt the sleep
    :
}

# Event listener that sends signals to main process
event_listener() {
    local main_pid=$1
    
    # Listen to Hyprland events in background
    socat -u UNIX-CONNECT:/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | while read -r event; do
        case "$event" in
            "openwindow"*|"closewindow"*|"activewindow"*|"workspace"*)
                log "Event detected: $event - waking up main loop"
                # Send USR1 signal to main process to interrupt sleep
                kill -USR1 "$main_pid" 2>/dev/null || break
                ;;
        esac
    done &
}

# Hybrid monitoring (polling + event interruption)
hybrid_monitor() {
    log "Starting hybrid monitoring (polling + event interruption)..."
    log "Check interval: ${CHECK_INTERVAL}s"
    
    # Set up signal handler for wakeup
    trap wakeup_handler USR1
    
    # Start event listener in background
    event_listener $$ &
    local event_listener_pid=$!
    
    # Main polling loop that can be interrupted
    while true; do
        check_and_switch
        
        # Sleep but allow interruption by USR1 signal
        sleep "$CHECK_INTERVAL" &
        wait $!
    done
}

# Polling-based monitoring (fallback)
polling_monitor() {
    log "Starting polling-based monitoring..."
    log "Check interval: ${CHECK_INTERVAL}s"
    
    while true; do
        check_and_switch
        sleep "$CHECK_INTERVAL"
    done
}

# Main monitoring loop
log "Starting window manager service..."
log "EWW binary: $EWW_BINARY"
log "Waybar binary: $WAYBAR_BINARY"

if [ "$USE_EVENTS" = "true" ] && command -v socat >/dev/null 2>&1 && [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    hybrid_monitor
else
    log "Event monitoring not available, falling back to polling"
    polling_monitor
fi