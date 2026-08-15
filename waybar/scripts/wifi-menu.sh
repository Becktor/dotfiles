#!/usr/bin/env bash

WIFI_DEVICE=$(nmcli -t -f DEVICE,TYPE device status | awk -F: '$2 == "wifi" { print $1; exit }')

if [ -z "$WIFI_DEVICE" ]; then
  notify-send "Wi-Fi" "No Wi-Fi device found"
  exit 1
fi

nmcli device wifi rescan ifname "$WIFI_DEVICE" 2>/dev/null

NETWORKS=$(nmcli -t -f SSID,SIGNAL,SECURITY,IN-USE device wifi list ifname "$WIFI_DEVICE" 2>/dev/null \
  | awk -F: '!seen[$1]++ && $1 != "" { 
      active = ($4 == "*") ? " ✓" : ""
      security = ($3 != "") ? " 󰌾" : ""
      printf "%s  %s%%%s%s\n", $1, $2, security, active
    }' \
  | sort -t'%' -k1 -rn)

if [ -z "$NETWORKS" ]; then
  notify-send "Wi-Fi" "No networks found"
  exit 1
fi

CHOSEN=$(echo "$NETWORKS" | rofi -dmenu -i -p "Wi-Fi" -theme-str 'window {width: 400px;}')

if [ -z "$CHOSEN" ]; then
  exit 0
fi

SSID=$(echo "$CHOSEN" | sed 's/  [0-9]*%.*//')

CURRENT_SSID=$(nmcli -g GENERAL.CONNECTION device show "$WIFI_DEVICE" 2>/dev/null)
if [ "$SSID" = "$CURRENT_SSID" ]; then
  ACTION=$(printf "Disconnect\nKeep connected" | rofi -dmenu -i -p "$SSID")
  if [ "$ACTION" = "Disconnect" ]; then
    nmcli device disconnect "$WIFI_DEVICE"
    notify-send "Wi-Fi" "Disconnected from $SSID"
  fi
  exit 0
fi

KNOWN=$(nmcli -t -f NAME connection show | grep -Fx "$SSID")
if [ -n "$KNOWN" ]; then
  nmcli connection up "$SSID" 2>/dev/null
  if [ $? -eq 0 ]; then
    notify-send "Wi-Fi" "Connected to $SSID"
  else
    notify-send "Wi-Fi" "Failed to connect to $SSID"
  fi
  exit 0
fi

PASSWORD=$(rofi -dmenu -p "Password for $SSID" -password -theme-str 'window {width: 400px;}')
if [ -z "$PASSWORD" ]; then
  exit 0
fi

nmcli device wifi connect "$SSID" password "$PASSWORD" ifname "$WIFI_DEVICE" 2>/dev/null
if [ $? -eq 0 ]; then
  notify-send "Wi-Fi" "Connected to $SSID"
else
  notify-send "Wi-Fi" "Failed to connect to $SSID"
fi
