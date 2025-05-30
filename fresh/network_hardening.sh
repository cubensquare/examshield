#!/bin/bash

# ======================
# SETUP
# ======================
LOG_DIR="/var/log/examshield"
mkdir -p "$LOG_DIR"

# Get active network interface and default gateway
INTERFACE=$(ip -o -4 route show to default | awk '{print $5}')
DEFAULT_GW=$(ip -o -4 route show to default | awk '{print $3}')
FULL_IP=$(ip -o -f inet addr show "$INTERFACE" | awk '{print $4}')
SUBNET_BASE=$(echo "$FULL_IP" | cut -d/ -f1 | cut -d. -f1-3)
BROADCAST_ADDR="${SUBNET_BASE}.255"
SUBNET_RANGE="${SUBNET_BASE}.0/24"

echo "[i] Interface: $INTERFACE" >> "$LOG_DIR/net_config.log"
echo "[i] Gateway: $DEFAULT_GW, Subnet: $SUBNET_RANGE" >> "$LOG_DIR/net_config.log"

# ======================
# IPTABLES - Restrict incoming ports
# ======================
iptables -F
iptables -X
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

# Allow HTTP/HTTPS and ICMP
iptables -A INPUT -i "$INTERFACE" -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -i "$INTERFACE" -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -i "$INTERFACE" -p icmp -j ACCEPT

# Ping only to gateway
iptables -A OUTPUT -p icmp -d "$DEFAULT_GW" -j ACCEPT
iptables -A OUTPUT -p icmp -j DROP

# Allow outgoing to gateway and broadcast
iptables -A OUTPUT -d "$DEFAULT_GW" -j ACCEPT
iptables -A OUTPUT -d "$BROADCAST_ADDR" -j ACCEPT

# Block PC-to-PC LAN access
iptables -A OUTPUT -d "$SUBNET_RANGE" -j DROP

# ======================
# Ethernet check
# ======================
ETH_COUNT=$(ls /sys/class/net | grep -E '^en' | wc -l)
if [ "$ETH_COUNT" -gt 1 ]; then
  echo "$(date): Extra Ethernet interfaces found: $ETH_COUNT" >> "$LOG_DIR/eth_check.log"
fi

# ======================
# Multiple IPs on interface
# ======================
IP_COUNT=$(ip addr show dev "$INTERFACE" | grep 'inet ' | wc -l)
if [ "$IP_COUNT" -gt 1 ]; then
  echo "$(date): Multiple IPs detected on $INTERFACE" >> "$LOG_DIR/ip_check.log"
fi

# ======================
# Detect foreign connections
# ======================
netstat -ntu | grep -v '127.0.0.1' | grep -v "${SUBNET_BASE}" >> "$LOG_DIR/foreign_conn.log"

# ======================
# Disable Intel AMT interface (if found)
# ======================
if [ -d /sys/class/net/amt0 ]; then
  echo "$(date): AMT interface found - disabling" >> "$LOG_DIR/amt_check.log"
  ip link set amt0 down
fi

echo "[✓] Network hardening script completed." >> "$LOG_DIR/net_config.log"
