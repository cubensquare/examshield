#!/bin/bash
LOG_DIR="/var/log/examshield"
mkdir -p "$LOG_DIR"

# Detect interface used for default route
DEFAULT_LINE=$(ip route | grep "^default" | head -n1)

if [ -z "$DEFAULT_LINE" ]; then
  # fallback: pick first non-loopback interface with IPv4
  INTERFACE=$(ip -o -4 addr | grep -v ' lo ' | awk '{print $2}' | head -n1)
  echo "[!] No default route found, using interface: $INTERFACE" >> "$LOG_DIR/net_fallback.log"
else
  INTERFACE=$(echo "$DEFAULT_LINE" | awk '{print $5}')
  DEFAULT_GW=$(echo "$DEFAULT_LINE" | awk '{print $3}')
fi

# Get IP address and derive subnet
IPADDR=$(ip -4 addr show "$INTERFACE" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
SUBNET_BASE=$(echo "$IPADDR" | cut -d. -f1-3)
BROADCAST="${SUBNET_BASE}.255"
SUBNET_RANGE="${SUBNET_BASE}.0/24"

# Use fallback if DEFAULT_GW is not resolved
[ -z "$DEFAULT_GW" ] && DEFAULT_GW="${SUBNET_BASE}.1"

# Log detected values
echo "[i] INTERFACE: $INTERFACE" >> "$LOG_DIR/net_config.log"
echo "[i] IPADDR: $IPADDR" >> "$LOG_DIR/net_config.log"
echo "[i] GATEWAY: $DEFAULT_GW" >> "$LOG_DIR/net_config.log"
echo "[i] SUBNET: $SUBNET_RANGE" >> "$LOG_DIR/net_config.log"

# ========== IPTABLES FIREWALL RULES ==========
iptables -F
iptables -X
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

iptables -A INPUT -i "$INTERFACE" -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -i "$INTERFACE" -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -i "$INTERFACE" -p icmp -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

iptables -A OUTPUT -p icmp -d "$DEFAULT_GW" -j ACCEPT
iptables -A OUTPUT -p icmp -j DROP

iptables -A OUTPUT -d "$DEFAULT_GW" -j ACCEPT
iptables -A OUTPUT -d "$BROADCAST" -j ACCEPT
iptables -A OUTPUT -d "$SUBNET_RANGE" -j DROP

# ========== DETECTIONS ==========
ETH_COUNT=$(ls /sys/class/net | grep -E '^en|^eth' | wc -l)
[ "$ETH_COUNT" -gt 1 ] && echo "$(date): Multiple interfaces" >> "$LOG_DIR/eth_check.log"

IP_COUNT=$(ip addr show dev "$INTERFACE" | grep 'inet ' | wc -l)
[ "$IP_COUNT" -gt 1 ] && echo "$(date): Multiple IPs on $INTERFACE" >> "$LOG_DIR/ip_check.log"

# Log foreign connections
netstat -ntu | grep -v '127.0.0.1' | grep -v "$SUBNET_BASE" >> "$LOG_DIR/foreign_conn.log"

# Disable AMT interface if found
[ -d /sys/class/net/amt0 ] && echo "$(date): AMT found - disabling" >> "$LOG_DIR/amt_check.log" && ip link set amt0 down

echo "[✓] Dynamic Network Hardening Completed" >> "$LOG_DIR/status.log"
