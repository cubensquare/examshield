#!/bin/bash

# Get PXE server IP from default route
PXE_IP=$(ip route | awk '/default/ {print $3}')

LOG_FILE="/var/log/pc_block.log"
echo "[INFO] Blocking PC-to-PC communication, allowing only PXE server $PXE_IP" > "$LOG_FILE"

# Allow only PXE server traffic by dropping others from the subnet
SUBNET=$(ip route | awk '/src/ {print $1}')

# Block INPUT from all peers in same subnet except PXE server
iptables -A INPUT -s "$SUBNET" ! -s "$PXE_IP" -j DROP

# Block OUTPUT to all peers in same subnet except PXE server
iptables -A OUTPUT -d "$SUBNET" ! -d "$PXE_IP" -j DROP

echo "[DONE] PC-to-PC traffic blocked successfully. Only $PXE_IP is allowed." >> "$LOG_FILE"
