#!/bin/bash

LOGFILE="/var/log/wireless_block.log"
echo "[INFO] Checking for wireless interfaces..." > "$LOGFILE"

# Get list of wireless interfaces (e.g., wlan0, wlp3s0, etc.)
WIFI_INTERFACES=$(iw dev 2>/dev/null | awk '$1=="Interface"{print $2}')

if [ -z "$WIFI_INTERFACES" ]; then
  echo "[OK] No wireless interfaces found." >> "$LOGFILE"
else
  for iface in $WIFI_INTERFACES; do
    echo "[ACTION] Blocking Wi-Fi interface: $iface" >> "$LOGFILE"
    ip link set "$iface" down
    echo "blacklist $(basename $(readlink /sys/class/net/$iface/device/driver))" >> /etc/modprobe.d/disable-wifi.conf
  done
fi
