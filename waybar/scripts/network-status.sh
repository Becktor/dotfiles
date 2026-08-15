#!/usr/bin/env bash

ethernet_device=$(nmcli -t -f DEVICE,TYPE,STATE device status | awk -F: '$2 == "ethernet" && $3 == "connected" { print $1; exit }')

json_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/' | tr -d '\n' | sed 's/\\n$//'
}

if [ -n "$ethernet_device" ]; then
  connection=$(nmcli -g GENERAL.CONNECTION device show "$ethernet_device" 2>/dev/null)
  tooltip="Ethernet connected: ${connection:-$ethernet_device}"
  printf '{"text":"󰈀","class":"ethernet","tooltip":"%s"}\n' "$(json_escape "$tooltip")"
  exit 0
fi

wifi_device=$(nmcli -t -f DEVICE,TYPE device status | awk -F: '$2 == "wifi" { print $1; exit }')

if [ -z "$wifi_device" ]; then
  printf '{"text":"󰤮","class":"disconnected","tooltip":"No Wi-Fi device"}\n'
  exit 0
fi

state=$(nmcli -t -f DEVICE,TYPE,STATE device status | awk -F: -v dev="$wifi_device" '$1 == dev { print $3; exit }')

if [ "$state" = "connected" ]; then
  ssid=$(nmcli -g GENERAL.CONNECTION device show "$wifi_device" 2>/dev/null)
  signal=$(nmcli -t -f IN-USE,SIGNAL device wifi list ifname "$wifi_device" 2>/dev/null | awk -F: '$1 == "*" { print $2; exit }')
  signal=${signal:-0}
  if [ "$signal" -ge 80 ]; then icon="󰤨"; elif [ "$signal" -ge 60 ]; then icon="󰤥"; elif [ "$signal" -ge 40 ]; then icon="󰤢"; elif [ "$signal" -ge 20 ]; then icon="󰤟"; else icon="󰤯"; fi
  tooltip="Wi-Fi connected: ${ssid:-$wifi_device} (${signal}%)"
  printf '{"text":"%s","class":"wifi","tooltip":"%s"}\n' "$icon" "$(json_escape "$tooltip")"
else
  printf '{"text":"󰤮","class":"disconnected","tooltip":"Wi-Fi disconnected"}\n'
fi
