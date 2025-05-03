#!/bin/bash

# Detect active non-loopback interfaces
ACTIVE_IFACES=$(ip -o link show | awk -F': ' '$2 != "lo" {print $2}')

# Count active interfaces
IFACE_COUNT=$(echo "$ACTIVE_IFACES" | wc -l)

# Acceptable interface pattern (e.g., eth0 or enpXsX)
ACCEPT_IFACE=$(echo "$ACTIVE_IFACES" | head -n 1)

LOG_FILE="/var/log/iface_check.log"
mkdir -p /var/log

echo "---- Interface Validation ----" >> "$LOG_FILE"
echo "Date: $(date)" >> "$LOG_FILE"
echo "Detected Interfaces:" >> "$LOG_FILE"
echo "$ACTIVE_IFACES" >> "$LOG_FILE"
echo "Accepting interface: $ACCEPT_IFACE" >> "$LOG_FILE"

if [ "$IFACE_COUNT" -gt 1 ]; then
    echo "⚠️ Multiple interfaces detected!" >> "$LOG_FILE"
    echo "❌ Blocking all except $ACCEPT_IFACE..." >> "$LOG_FILE"

    for IFACE in $ACTIVE_IFACES; do
        if [ "$IFACE" != "$ACCEPT_IFACE" ]; then
            ip link set "$IFACE" down
            echo "⛔ Interface $IFACE brought down." >> "$LOG_FILE"
        fi
    done
else
    echo "✅ Only one interface is active. No action required." >> "$LOG_FILE"
fi

echo "-----------------------------" >> "$LOG_FILE"
