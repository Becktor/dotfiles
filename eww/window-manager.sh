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

# Function to check if there are active windows
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
    
    # Open panel if not already open
    if ! $EWW_BINARY active-windows 2>/dev/null | grep -q "panel:"; then
        log "Opening eww panel..."
        $EWW_BINARY open panel
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
    if has_active_windows; then
        # Windows are active - use waybar
        if [ "$current_state" != "waybar" ]; then
            log "Active windows detected - switching to waybar"
            hide_eww_panel
            show_waybar
            current_state="waybar"
        fi
    else
        # No active windows - use eww panel
        if [ "$current_state" != "eww" ]; then
            log "No active windows - switching to eww panel"
            hide_waybar
            show_eww_panel
            current_state="eww"
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