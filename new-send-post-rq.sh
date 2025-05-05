#!/bin/bash

# Dynamically get the PXE server IP from default route
PXE_IP=$(ip route | awk '/default/ {print $3}')

# Validate IP
if [[ -z "$PXE_IP" ]]; then
  echo "[!] PXE_IP not found via default route."
  exit 1
fi

# Extract interface and MAC address
IFACE=$(ip -o link show | awk -F': ' '$2 !~ /^lo/ {print $2; exit}')
MAC=$(cat /sys/class/net/"$IFACE"/address)
IP=$(hostname -I | awk '{print $1}')
HOSTNAME=$(hostname)
STATUS="booted"

# Send status to PXE server
curl -X POST "http://$PXE_IP:5000/register" \
     -H "Content-Type: application/json" \
     -d "{
           \"mac\": \"$MAC\",
           \"ip\": \"$IP\",
           \"hostname\": \"$HOSTNAME\",
           \"status\": \"$STATUS\"
         }" || echo "[!] Failed to send PXE status"
