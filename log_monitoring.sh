#!/bin/bash

LOG_DIR="/var/log/examshield"
mkdir -p "$LOG_DIR"

# Log network traffic periodically (source & destination IPs)
nohup watch -n 60 'netstat -ntu | grep ESTABLISHED >> $LOG_DIR/network_traffic.log' > /dev/null 2>&1 &

# Monitor USB insertions and rejections using udevadm
nohup udevadm monitor --udev --subsystem-match=usb >> $LOG_DIR/usb_events.log 2>&1 &

# Log foreign PC connections (ping attempts, netstat)
nohup watch -n 60 'netstat -an | grep -v "127.0.0.1" | grep -v "::1" | grep ESTABLISHED >> $LOG_DIR/foreign_connections.log' > /dev/null 2>&1 &

# Log iptables rejected attempts
nohup watch -n 60 'dmesg | grep "IN=" | grep -i "DROP" >> $LOG_DIR/firewall_rejects.log' > /dev/null 2>&1 &

# Timestamp for script startup
echo "[✓] Logging started at $(date)" >> "$LOG_DIR/startup.log"
