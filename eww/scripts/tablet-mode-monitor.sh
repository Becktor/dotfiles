#!/bin/bash

# Tablet Mode Monitor for ThinkPad Yoga
# Detects tablet mode and automatically rotates screen and disables keyboard

MONITOR="eDP-1"
RESOLUTION="1920x1200@60"
KEYBOARD_DEVICE="at-translated-set-2-keyboard"
TOUCHPAD_DEVICE=""
CURRENT_MODE=""
LOG_FILE="/tmp/tablet-mode.log"
STATE_FILE="/tmp/tablet-mode-state"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo "$1"
}

get_touchpad_device() {
    if [ -z "$TOUCHPAD_DEVICE" ]; then
        TOUCHPAD_DEVICE=$(hyprctl devices | grep -A 5 "Touchpads:" | grep -o "at [^:]*" | head -1 | sed 's/at //')
        if [ -n "$TOUCHPAD_DEVICE" ]; then
            log_message "Found touchpad device: $TOUCHPAD_DEVICE"
        fi
    fi
}

enable_laptop_mode() {
    log_message "Enabling laptop mode"
    
    # Reset screen rotation
    hyprctl keyword monitor "$MONITOR,$RESOLUTION,0x0,1,transform,0"
    
    # Enable keyboard
    hyprctl keyword device:"$KEYBOARD_DEVICE":enabled true
    
    # Enable touchpad if detected
    get_touchpad_device
    if [ -n "$TOUCHPAD_DEVICE" ]; then
        hyprctl keyword device:"$TOUCHPAD_DEVICE":enabled true
    fi
    
    echo "laptop" > "$STATE_FILE"
    CURRENT_MODE="laptop"
    log_message "Laptop mode enabled"
}

enable_tablet_mode() {
    log_message "Enabling tablet mode"
    
    # Rotate screen (adjust transform value based on preference)
    # transform,1 = 90 degrees clockwise
    # transform,3 = 270 degrees clockwise (90 counter-clockwise)
    hyprctl keyword monitor "$MONITOR,$RESOLUTION,0x0,1,transform,1"
    
    # Disable keyboard
    hyprctl keyword device:"$KEYBOARD_DEVICE":enabled false
    
    # Disable touchpad if detected
    get_touchpad_device
    if [ -n "$TOUCHPAD_DEVICE" ]; then
        hyprctl keyword device:"$TOUCHPAD_DEVICE":enabled false
    fi
    
    echo "tablet" > "$STATE_FILE"
    CURRENT_MODE="tablet"
    log_message "Tablet mode enabled"
}

check_acpi_tablet_mode() {
    # Check if we can detect tablet mode through ACPI
    if [ -f /proc/acpi/event ]; then
        local acpi_state=$(acpi_listen -c 1 -t 1 2>/dev/null | grep "video/tabletmode TBLT" | awk '{print $4}')
        if [ "$acpi_state" = "00000001" ]; then
            echo "tablet"
        elif [ "$acpi_state" = "00000000" ]; then
            echo "laptop"
        fi
    fi
}

check_hinge_sensor() {
    # Check hinge sensor for tablet mode detection
    local hinge_device="/sys/bus/iio/devices/iio:device3"
    
    if [ -f "$hinge_device/in_angl0_raw" ]; then
        local angle0=$(cat "$hinge_device/in_angl0_raw" 2>/dev/null || echo 0)
        local angle1=$(cat "$hinge_device/in_angl1_raw" 2>/dev/null || echo 0)
        local angle2=$(cat "$hinge_device/in_angl2_raw" 2>/dev/null || echo 0)
        
        log_message "Hinge angles: $angle0, $angle1, $angle2"
        
        # Detect tablet mode based on hinge angles
        # Adjust these thresholds based on your device's behavior
        local max_angle=$angle0
        [ "$angle1" -gt "$max_angle" ] && max_angle=$angle1
        [ "$angle2" -gt "$max_angle" ] && max_angle=$angle2
        
        # If any angle > 180 degrees (adjust threshold as needed)
        if [ "$max_angle" -gt 180 ] || [ "$angle0" -gt 160 ] || [ "$angle1" -gt 160 ]; then
            echo "tablet"
            return
        else
            echo "laptop"
            return
        fi
    fi
    
    echo "unknown"
}

check_accelerometer_orientation() {
    # Check both accelerometer devices for tablet mode detection
    local device0="/sys/bus/iio/devices/iio:device0"
    local device1="/sys/bus/iio/devices/iio:device1"
    
    if [ -f "$device0/in_accel_x_raw" ] && [ -f "$device1/in_accel_x_raw" ]; then
        local x0=$(cat "$device0/in_accel_x_raw" 2>/dev/null || echo 0)
        local y0=$(cat "$device0/in_accel_y_raw" 2>/dev/null || echo 0)
        local z0=$(cat "$device0/in_accel_z_raw" 2>/dev/null || echo 0)
        
        local x1=$(cat "$device1/in_accel_x_raw" 2>/dev/null || echo 0)
        local y1=$(cat "$device1/in_accel_y_raw" 2>/dev/null || echo 0)
        local z1=$(cat "$device1/in_accel_z_raw" 2>/dev/null || echo 0)
        
        log_message "Accelerometers - Device0: x=$x0, y=$y0, z=$z0 | Device1: x=$x1, y=$y1, z=$z1"
        
        # Detect tablet mode based on observed patterns:
        # Normal laptop mode: Device0 x~24k, y~-897k, z~-445k | Device1 x~13k, y~16k, z~-993k
        # Tablet mode: Both devices show significant changes, especially |x| values become much larger
        
        # Check if either device shows high x-axis values (indicating rotation)
        local abs_x0=${x0#-}
        local abs_x1=${x1#-}
        
        # If either accelerometer shows high x values (> 500k), likely in tablet mode
        if [ "$abs_x0" -gt 500000 ] || [ "$abs_x1" -gt 500000 ]; then
            echo "tablet"
            return
        fi
        
        # Check for normal laptop orientation patterns
        # Device0 should have high negative y (~-900k) and Device1 high negative z (~-993k)
        local abs_y0=${y0#-}
        local abs_z1=${z1#-}
        
        if [ "$abs_y0" -gt 800000 ] && [ "$abs_z1" -gt 900000 ] && [ "$abs_x0" -lt 100000 ] && [ "$abs_x1" -lt 100000 ]; then
            echo "laptop"
            return
        fi
    fi
    
    echo "unknown"
}

detect_tablet_mode() {
    # First try hinge sensor (most reliable for ThinkPad Yoga)
    local mode=$(check_hinge_sensor)
    
    # If hinge sensor doesn't work, try ACPI
    if [ -z "$mode" ] || [ "$mode" = "unknown" ]; then
        mode=$(check_acpi_tablet_mode)
    fi
    
    # If ACPI doesn't give us info, try accelerometer as last resort
    if [ -z "$mode" ] || [ "$mode" = "unknown" ]; then
        mode=$(check_accelerometer_orientation)
    fi
    
    echo "$mode"
}

initialize() {
    log_message "Initializing tablet mode monitor"
    
    # Create state file if it doesn't exist
    if [ ! -f "$STATE_FILE" ]; then
        echo "laptop" > "$STATE_FILE"
    fi
    
    CURRENT_MODE=$(cat "$STATE_FILE" 2>/dev/null || echo "laptop")
    log_message "Current mode: $CURRENT_MODE"
    
    # Get touchpad device name
    get_touchpad_device
}

monitor_mode_changes() {
    log_message "Starting tablet mode monitoring"
    
    while true; do
        local detected_mode=$(detect_tablet_mode)
        
        if [ "$detected_mode" != "unknown" ] && [ "$detected_mode" != "$CURRENT_MODE" ]; then
            log_message "Mode change detected: $CURRENT_MODE -> $detected_mode"
            
            case "$detected_mode" in
                "tablet")
                    enable_tablet_mode
                    ;;
                "laptop")
                    enable_laptop_mode
                    ;;
            esac
        fi
        
        sleep 2
    done
}

case "$1" in
    "start")
        initialize
        monitor_mode_changes
        ;;
    "stop")
        pkill -f "tablet-mode-monitor.sh"
        log_message "Tablet mode monitor stopped"
        ;;
    "status")
        if [ -f "$STATE_FILE" ]; then
            cat "$STATE_FILE"
        else
            echo "unknown"
        fi
        ;;
    "tablet")
        initialize
        enable_tablet_mode
        ;;
    "laptop")
        initialize
        enable_laptop_mode
        ;;
    "toggle")
        initialize
        if [ "$CURRENT_MODE" = "tablet" ]; then
            enable_laptop_mode
        else
            enable_tablet_mode
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|status|tablet|laptop|toggle}"
        echo "  start  - Start monitoring for tablet mode changes"
        echo "  stop   - Stop monitoring"
        echo "  status - Show current mode"
        echo "  tablet - Force tablet mode"
        echo "  laptop - Force laptop mode"
        echo "  toggle - Toggle between modes"
        exit 1
        ;;
esac