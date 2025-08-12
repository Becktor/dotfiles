#!/bin/bash

# Tablet Mode Monitor v2 for ThinkPad Yoga
# Uses Intel HID switches for real-time tablet mode detection

MONITOR="eDP-1"
RESOLUTION="1920x1200@60"
KEYBOARD_DEVICE="at-translated-set-2-keyboard"
TOUCHPAD_DEVICE=""
INTEL_HID_EVENT="/dev/input/event8"
CURRENT_MODE=""
LOG_FILE="/tmp/tablet-mode.log"
STATE_FILE="/tmp/tablet-mode-state"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo "$1"
}

get_keyboard_event_device() {
    # Find the keyboard event device
    KEYBOARD_EVENT=$(cat /proc/bus/input/devices | grep -A 5 "AT Translated Set 2 keyboard" | grep "Handlers" | sed 's/.*event\([0-9]*\).*/\1/')
    if [ -n "$KEYBOARD_EVENT" ]; then
        KEYBOARD_EVENT_PATH="/dev/input/event$KEYBOARD_EVENT"
        log_message "Found keyboard event device: $KEYBOARD_EVENT_PATH"
    fi
}

get_touchpad_device() {
    if [ -z "$TOUCHPAD_DEVICE" ]; then
        TOUCHPAD_DEVICE=$(hyprctl devices | grep -A 1 "Mouse at" | grep "touchpad" | awk '{print $1}' | head -1)
        if [ -n "$TOUCHPAD_DEVICE" ]; then
            log_message "Found touchpad device: $TOUCHPAD_DEVICE"
        fi
    fi
}

disable_keyboard() {
    get_keyboard_event_device
    if [ -n "$KEYBOARD_EVENT_PATH" ] && [ -c "$KEYBOARD_EVENT_PATH" ]; then
        # Block keyboard input by redirecting to /dev/null
        log_message "Disabling keyboard at $KEYBOARD_EVENT_PATH"
        echo "keyboard_disabled" > "/tmp/tablet-keyboard-state"
    else
        log_message "Could not find keyboard event device"
    fi
}

enable_keyboard() {
    if [ -f "/tmp/tablet-keyboard-state" ]; then
        rm -f "/tmp/tablet-keyboard-state"
        log_message "Keyboard re-enabled"
    fi
}

disable_touchpad() {
    # Find the touchpad event device
    TOUCHPAD_EVENT=$(cat /proc/bus/input/devices | grep -A 5 "ELAN.*Touchpad" | grep "Handlers" | sed 's/.*event\([0-9]*\).*/\1/')
    if [ -n "$TOUCHPAD_EVENT" ]; then
        TOUCHPAD_EVENT_PATH="/dev/input/event$TOUCHPAD_EVENT"
        log_message "Disabling touchpad at $TOUCHPAD_EVENT_PATH"
        echo "touchpad_disabled" > "/tmp/tablet-touchpad-state"
        # Store the device path for later re-enabling
        echo "$TOUCHPAD_EVENT_PATH" > "/tmp/tablet-touchpad-device"
    else
        log_message "Could not find touchpad event device"
    fi
}

enable_touchpad() {
    if [ -f "/tmp/tablet-touchpad-state" ]; then
        rm -f "/tmp/tablet-touchpad-state"
        rm -f "/tmp/tablet-touchpad-device"
        log_message "Touchpad re-enabled"
    fi
}

enable_laptop_mode() {
    log_message "Enabling laptop mode"
    
    # Reset screen rotation
    hyprctl keyword monitor "$MONITOR,$RESOLUTION,0x0,1,transform,0"
    
    # Reset touchscreen input rotation
    hyprctl keyword input:touchdevice:transform 0
    
    # Reset pen input rotation
    hyprctl keyword input:tablet:transform 0
    
    # Enable keyboard using libinput
    enable_keyboard
    
    # Enable touchpad
    enable_touchpad
    
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
    
    # Rotate touchscreen input to match display
    hyprctl keyword input:touchdevice:transform 1
    
    # Rotate pen input to match display
    hyprctl keyword input:tablet:transform 1
    
    # Disable keyboard
    disable_keyboard
    
    # Disable touchpad
    disable_touchpad
    
    echo "tablet" > "$STATE_FILE"
    CURRENT_MODE="tablet"
    log_message "Tablet mode enabled"
}

check_input_device_permissions() {
    if [ ! -r "$INTEL_HID_EVENT" ]; then
        log_message "Cannot read $INTEL_HID_EVENT - may need to add user to input group"
        log_message "Run: sudo usermod -a -G input $USER"
        return 1
    fi
    return 0
}

monitor_intel_hid_events() {
    log_message "Starting Intel HID event monitoring on $INTEL_HID_EVENT"
    
    if ! check_input_device_permissions; then
        log_message "Falling back to accelerometer monitoring"
        monitor_accelerometer_fallback
        return
    fi
    
    # Use hexdump to monitor input events
    # SW_TABLET_MODE events: type=0x05 (EV_SW), code=0x01 (SW_TABLET_MODE), value=0/1
    hexdump -C "$INTEL_HID_EVENT" | while read -r line; do
        # Parse hexdump output for switch events
        # Look for EV_SW (0x05) and SW_TABLET_MODE (0x01)
        if echo "$line" | grep -q "05 00 01 00"; then
            # Extract the value (0 or 1) from the event
            if echo "$line" | grep -q "01 00 00 00"; then
                # Tablet mode activated
                log_message "Intel HID: Tablet mode detected"
                if [ "$CURRENT_MODE" != "tablet" ]; then
                    enable_tablet_mode
                fi
            elif echo "$line" | grep -q "00 00 00 00"; then
                # Laptop mode activated
                log_message "Intel HID: Laptop mode detected"
                if [ "$CURRENT_MODE" != "laptop" ]; then
                    enable_laptop_mode
                fi
            fi
        fi
    done
}

monitor_accelerometer_fallback() {
    log_message "Using accelerometer fallback monitoring"
    
    while true; do
        local detected_mode=$(check_accelerometer_orientation)
        
        if [ "$detected_mode" != "unknown" ] && [ "$detected_mode" != "$CURRENT_MODE" ]; then
            log_message "Accelerometer: Mode change detected: $CURRENT_MODE -> $detected_mode"
            
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
        
        # Check if either device shows high x-axis values (indicating rotation)
        local abs_x0=${x0#-}
        local abs_x1=${x1#-}
        
        # If either accelerometer shows high x values (> 500k), likely in tablet mode
        if [ "$abs_x0" -gt 500000 ] || [ "$abs_x1" -gt 500000 ]; then
            echo "tablet"
            return
        fi
        
        # Check for normal laptop orientation patterns
        local abs_y0=${y0#-}
        local abs_z1=${z1#-}
        
        if [ "$abs_y0" -gt 800000 ] && [ "$abs_z1" -gt 900000 ] && [ "$abs_x0" -lt 100000 ] && [ "$abs_x1" -lt 100000 ]; then
            echo "laptop"
            return
        fi
    fi
    
    echo "unknown"
}

initialize() {
    log_message "Initializing tablet mode monitor v2"
    
    # Create state file if it doesn't exist
    if [ ! -f "$STATE_FILE" ]; then
        echo "laptop" > "$STATE_FILE"
    fi
    
    CURRENT_MODE=$(cat "$STATE_FILE" 2>/dev/null || echo "laptop")
    log_message "Current mode: $CURRENT_MODE"
    
    # Get touchpad device name
    get_touchpad_device
    
    # Check if Intel HID device exists
    if [ ! -e "$INTEL_HID_EVENT" ]; then
        log_message "Intel HID device $INTEL_HID_EVENT not found, using accelerometer fallback"
    else
        log_message "Found Intel HID device: $INTEL_HID_EVENT"
    fi
}

case "$1" in
    "start")
        initialize
        if [ -e "$INTEL_HID_EVENT" ]; then
            monitor_intel_hid_events
        else
            monitor_accelerometer_fallback
        fi
        ;;
    "stop")
        pkill -f "tablet-mode-monitor"
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
    "test-events")
        if [ -e "$INTEL_HID_EVENT" ]; then
            if check_input_device_permissions; then
                echo "Monitoring Intel HID events (Ctrl+C to stop):"
                echo "Try folding your laptop to see tablet mode events..."
                hexdump -C "$INTEL_HID_EVENT"
            else
                echo "Cannot access $INTEL_HID_EVENT"
                echo "Run: sudo usermod -a -G input $USER"
                echo "Then log out and back in."
            fi
        else
            echo "Intel HID device not found at $INTEL_HID_EVENT"
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|status|tablet|laptop|toggle|test-events}"
        echo "  start       - Start monitoring for tablet mode changes"
        echo "  stop        - Stop monitoring"
        echo "  status      - Show current mode"
        echo "  tablet      - Force tablet mode"
        echo "  laptop      - Force laptop mode"
        echo "  toggle      - Toggle between modes"
        echo "  test-events - Test Intel HID event monitoring"
        exit 1
        ;;
esac