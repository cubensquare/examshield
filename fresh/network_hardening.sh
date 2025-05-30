#!/bin/bash

LOG_DIR="/var/log/examshield"
mkdir -p "$LOG_DIR"

# Ensure required tools exist
for cmd in ip iptables awk grep cut ls; do
  command -v $cmd >/dev/null || { echo "[!] Missing command: $cmd" >> "$LOG_DIR/errors.log"; exit 1; }
done

# Get default interface and gateway
INTERFACE=$(ip -o -4 route show to default | awk '{print $5}')
DEFAULT_GW=$(ip -o -4 route show to default | awk '{print $3}')
SUBNET=$(ip -o -f inet addr show "$INTERFACE" | awk '{print $4}' | cut -d/ -f1 | cut -d. -f1-3)

echo "[i] Using interface: $INTERFACE" >> "$LOG_DIR/net_config.log"
echo "[i] Gateway: $DEFAULT_GW, Subnet: ${SUBNET}.0/24" >> "$LOG_DIR/net_config.log"

# ========== IPTABLES ==========
iptables -F
iptables -X
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# Allow localhost loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow incoming HTTP, HTTPS, ICMP
iptables -A INPUT -i "$INTERFACE" -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -i "$INTERFACE" -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -i "$INTERFACE" -p icmp -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Ping only gateway
iptables -A OUTPUT -o "$INTERFACE" -p icmp -d "$DEFAULT_GW" -j ACCEPT
iptables -A OUTPUT -o "$INTERFACE" -p icmp -j DROP

# Allow output to PXE server/gateway only
iptables -A OUTPUT -d "$DEFAULT_GW" -j ACCEPT

# Block PC-to-PC communication (allow gateway + broadcast)
iptables -A OUTPUT -d "${SUBNET}.255" -j ACCEPT
iptables -A OUTPUT -d "${SUBNET}.0/24" -j DROP

# ========== Checks ==========

# 1. Check for multiple Ethernet interfaces
ETH_COUNT=$(ls /sys/class/net | grep -E '^en' | wc -l)
if [ "$ETH_COUNT" -gt 1 ]; then
  echo "$(date): Extra Ethernet interfaces found: $ETH_COUNT" >> "$LOG_DIR/eth_check.log"
fi

# 2. Check for multiple IPs on the same interface
IP_COUNT=$(ip addr show dev "$INTERFACE" | grep 'inet ' | wc -l)
if [ "$IP_COUNT" -gt 1 ]; then
  echo "$(date): Multiple IPs detected on $INTERFACE" >> "$LOG_DIR/ip_check.log"
fi

# 3. Log foreign connections (excluding localhost and subnet)
if command -v netstat >/dev/null; then
  netstat -ntu | grep -v '127.0.0.1' | grep -v "${SUBNET}" >> "$LOG_DIR/foreign_conn.log"
else
  echo "[!] netstat not available, skipping foreign connection log." >> "$LOG_DIR/foreign_conn.log"
fi

# 4. Disable AMT if present
if [ -d /sys/class/net/amt0 ]; then
  echo "$(date): AMT interface found - disabling" >> "$LOG_DIR/amt_check.log"
  ip link set amt0 down
fi

echo "[✓] Network hardening completed at $(date)" >> "$LOG_DIR/status.log"
