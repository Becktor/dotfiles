# ThinkPad Yoga Tablet Mode Setup

## Overview
This setup provides automatic screen rotation and keyboard disabling for ThinkPad Yoga devices in tablet mode.

## Components Created

### Scripts
- `eww/scripts/tablet-mode-monitor.sh` - Main monitoring script for automatic tablet mode detection
- `eww/scripts/toggle-rotation.sh` - Manual screen rotation control

### Configuration Updates
- `eww/widgets/hardware-controls.yuck` - Added rotation and tablet mode controls to the hardware panel
- `hypr/hyprland.conf` - Added keyboard shortcuts for tablet mode control
- `systemd/user/tablet-mode.service` - Systemd service for automatic monitoring

### Keyboard Shortcuts Added
- `Super + R` - Cycle through screen rotations
- `Super + Shift + R` - Toggle between tablet and laptop mode
- `Super + Ctrl + R` - Reset to normal (landscape) orientation

## Manual Setup Required

### 1. Enable Systemd Service
```bash
# Copy service file to user systemd directory
mkdir -p ~/.config/systemd/user
cp ~/git/dotfiles/systemd/user/tablet-mode.service ~/.config/systemd/user/

# Enable and start the service
systemctl --user enable tablet-mode.service
systemctl --user start tablet-mode.service

# Check service status
systemctl --user status tablet-mode.service
```

### 2. Device Configuration
The scripts automatically detect device names, but you may need to adjust these in the scripts if detection fails:

- **Monitor**: Currently set to `eDP-1` with resolution `1920x1200@60`
- **Keyboard**: Currently set to `at-translated-set-2-keyboard`
- **Touchpad**: Auto-detected from hyprctl devices

To find your device names:
```bash
# Check monitors
hyprctl monitors

# Check input devices  
hyprctl devices
```

### 3. Test the Setup

#### Manual Testing
```bash
# Test rotation script
~/.config/eww/scripts/toggle-rotation.sh cycle
~/.config/eww/scripts/toggle-rotation.sh status

# Test tablet mode script
~/.config/eww/scripts/tablet-mode-monitor.sh toggle
~/.config/eww/scripts/tablet-mode-monitor.sh status
```

#### Widget Testing
- Open your eww hardware controls panel
- Look for the new "ROTATION & TABLET" section
- Test the rotation buttons (⬜ ⬅️ ⬛ ➡️)
- Test the tablet mode buttons (💻 📱 🔄)

## Hardware Detection Methods

The system attempts to detect tablet mode using:

1. **ACPI Events** - Monitors for `video/tabletmode TBLT` events
2. **Accelerometer Data** - Reads from `/sys/bus/iio/devices/iio:device*/in_accel_*_raw`

### Troubleshooting Detection

If automatic detection doesn't work:

1. **Check for ACPI support**:
   ```bash
   # Install acpi tools if not present
   sudo pacman -S acpi acpid  # Arch Linux
   sudo apt install acpi acpid  # Ubuntu/Debian
   
   # Test ACPI listening
   acpi_listen
   # Then fold your laptop and see if events appear
   ```

2. **Check for accelerometer**:
   ```bash
   # Look for IIO devices
   find /sys/bus/iio/devices -name "iio:device*" -type d
   
   # Install iio-sensor-proxy if available
   sudo pacman -S iio-sensor-proxy  # Arch Linux
   sudo apt install iio-sensor-proxy  # Ubuntu/Debian
   ```

3. **Manual fallback**:
   If automatic detection fails, you can still use manual controls through:
   - Widget buttons
   - Keyboard shortcuts
   - Command line scripts

## Customization

### Rotation Preferences
Edit `tablet-mode-monitor.sh` to change the default tablet rotation:
- `transform,1` = 90° clockwise (current default)
- `transform,3` = 90° counter-clockwise
- `transform,2` = 180° upside down

### Device Names
Update device names in `tablet-mode-monitor.sh` if auto-detection fails:
```bash
MONITOR="your-monitor-name"
KEYBOARD_DEVICE="your-keyboard-device"
```

### Additional Features
You can extend the scripts to:
- Adjust touchscreen input rotation
- Control screen brightness in tablet mode
- Disable specific keys instead of entire keyboard
- Add custom vibration/haptic feedback

## Logs and Debugging

Monitor logs for troubleshooting:
```bash
# Service logs
journalctl --user -u tablet-mode.service -f

# Script logs
tail -f /tmp/tablet-mode.log

# Test detection manually
~/.config/eww/scripts/tablet-mode-monitor.sh start
# (Run in separate terminal and test folding the device)
```