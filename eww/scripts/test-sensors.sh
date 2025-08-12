#!/bin/bash

echo "Testing ThinkPad Yoga sensors..."
echo "Press Ctrl+C to stop"
echo "Try folding your laptop while this runs"
echo

while true; do
    echo "$(date '+%H:%M:%S') - Hinge: $(cat /sys/bus/iio/devices/iio:device3/in_angl0_raw) $(cat /sys/bus/iio/devices/iio:device3/in_angl1_raw) $(cat /sys/bus/iio/devices/iio:device3/in_angl2_raw) | Accel: $(cat /sys/bus/iio/devices/iio:device0/in_accel_x_raw) $(cat /sys/bus/iio/devices/iio:device0/in_accel_y_raw) $(cat /sys/bus/iio/devices/iio:device0/in_accel_z_raw)"
    sleep 1
done