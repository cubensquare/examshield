#!/bin/bash

# Get PXE server IP dynamically
PXE_SERVER_IP=$(ip route | awk '/default/ {print $3}')
LOG_FILE="/var/log/foreign_connection.log"

# Allow traffic from localhost and PXE server
iptables -A INPUT -s 127.0.0.1 -j ACCEPT
iptables -A INPUT -s "$PXE_SERVER_IP" -j ACCEPT

# Log and drop all other incoming connections
iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "[FOREIGN_CONN] " --log-level 4
iptables -A INPUT -j DROP

# Save logs separately
grep -i "\[FOREIGN_CONN\]" /var/log/kern.log >> "$LOG_FILE" 2>/dev/null &
