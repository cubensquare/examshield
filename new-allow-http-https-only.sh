#!/bin/bash

LOGFILE="/var/log/http_https_only.log"

echo "[i] Restricting outbound traffic to only HTTP (80) and HTTPS (443)..." | tee -a "$LOGFILE"

# Flush existing rules to avoid duplicates
iptables -F OUTPUT

# Allow loopback
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established connections
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow HTTP (80) and HTTPS (443)
iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT

# Drop everything else
iptables -A OUTPUT -j DROP

echo "[✓] Outbound restricted to HTTP and HTTPS only at $(date)" | tee -a "$LOGFILE"
