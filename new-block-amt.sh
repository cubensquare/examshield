#!/bin/bash

LOG_FILE="/var/log/amt_status.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

echo "[${TIMESTAMP}] Starting AMT check..." >> "$LOG_FILE"

# Check if AMT is present via lspci or dmidecode
if dmidecode | grep -iq "Intel.*AMT"; then
    echo "[${TIMESTAMP}] Intel AMT detected!" >> "$LOG_FILE"
else
    echo "[${TIMESTAMP}] Intel AMT not detected." >> "$LOG_FILE"
fi

# Disable AMT module if present
if lsmod | grep -q mei; then
    echo "[${TIMESTAMP}] Disabling mei module (used by AMT)..." >> "$LOG_FILE"
    rmmod mei
    rmmod mei_me
    echo "[${TIMESTAMP}] AMT (MEI) modules removed." >> "$LOG_FILE"
else
    echo "[${TIMESTAMP}] MEI module not loaded." >> "$LOG_FILE"
fi

# Setup monitoring for any setting changes
inotifywait -mq -e modify /etc /boot /sys/firmware 2>/dev/null | \
while read -r path action file; do
    echo "[WARNING][${TIMESTAMP}] Potential config change attempt in $path$file" >> "$LOG_FILE"
done &

exit 0
