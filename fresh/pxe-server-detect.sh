#!/bin/bash

LOG_DIR="/var/log/examshield"
mkdir -p "$LOG_DIR"

# Find default network interface
IFACE=$(ip route | grep '^default' | awk '{print $5}' | head -n1)
[ -z "$IFACE" ] && IFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -E '^en|^eth' | head -n1)

# Detect PXE server via ARP
PXE_SERVER_IP=$(ip neigh | grep "$IFACE" | grep -w "REACHABLE" | awk '{print $1}' | head -n1)

# Fallback to first remote IP in routing table
[ -z "$PXE_SERVER_IP" ] && PXE_SERVER_IP=$(netstat -rn | grep "$IFACE" | grep -v '^0.0.0.0' | awk '{print $1}' | head -n1)

# Final fallback
[ -z "$PXE_SERVER_IP" ] && PXE_SERVER_IP="unknown"

echo "$(date): PXE Server IP detected as $PXE_SERVER_IP" >> "$LOG_DIR/pxe_server_detect.log"
