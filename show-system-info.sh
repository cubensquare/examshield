#!/bin/bash

# Auto-detect active user
PXE_USERNAME=$(who | awk '{print $1}' | head -n 1)

# Get IP, MAC, Hostname
IFACE=$(ip route | awk '/default/ {print $5}')
IP=$(ip -4 addr show "$IFACE" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
MAC=$(cat /sys/class/net/"$IFACE"/address)
HOSTNAME=$(hostname)

INFO="Hostname: $HOSTNAME\nIP Address: $IP\nMAC Address: $MAC"

# Show via zenity
export DISPLAY=:0
export XAUTHORITY="/home/$PXE_USERNAME/.Xauthority"

sudo -u "$PXE_USERNAME" zenity --info --title="PXE System Info" --width=300 --height=150 --text="$INFO"
