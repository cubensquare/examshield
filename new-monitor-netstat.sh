#!/bin/bash

PXE_SERVER_IP=$(ip route | awk '/default/ {print $3}')
LOG_FILE="/var/log/netstat_monitor.log"
ALLOWED_IPS="$PXE_SERVER_IP 127.0.0.1"

while true; do
    echo "----- $(date) -----" >> "$LOG_FILE"
    netstat -n | grep ESTABLISHED | awk '{print $5}' | cut -d: -f1 | sort | uniq | while read ip; do
        if [[ ! " $ALLOWED_IPS " =~ " $ip " ]]; then
            echo "[ALERT] Foreign connection to $ip detected!" >> "$LOG_FILE"
        fi
    done
    sleep 60  # Run every 1 minute
done
