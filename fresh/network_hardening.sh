#!/bin/bash

LOG_DIR="/var/log/examshield"
mkdir -p "$LOG_DIR"

# Get default interface and gateway dynamically
INTERFACE=$(ip -o -4 route show to default | awk '{print $5}')
DEFAULT_GW=$(ip -o -4 route show to default | awk '{print $3}')
SUBNET=$(ip -o -f inet addr show $INTERFACE | awk '{print $4}' | cut -d/ -f1 | cut -d. -f1-3)

echo "[i] Using interface: $INTERFACE" >> "$LOG_DIR/net_config.log"
echo "[i] Gateway: $DEFAULT_GW, Subnet: $SUBNET.0/24" >> "$LOG_DIR/net_config.log"

# ======================
# 1. Restrict incoming ports to HTTP, HTTPS, ICMP
# ======================
iptables -F
iptables -A INPUT -i $INTERFACE -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -i $INTERFACE -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -i $INTERFACE -p icmp -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -P INPUT DROP

# ======================
# 2. Ping allowed only to gateway
# ======================
iptables -A OUTPUT -p icmp -d $DEFAULT_GW -j ACCEPT
iptables -A OUTPUT -p icmp -j DROP

# ======================
# 3. Multiple Ethernet interface detection
# ======================
ETH_COUNT=$(ls /sys/class/net | grep -E '^en' | wc -l)
if [ "$ETH_COUNT" -gt 1 ]; then
  echo "$(date): Extra Ethernet interfaces found: $ETH_COUNT" >> "$LOG_DIR/eth_check.log"
fi

# ======================
# 4. Multiple IPs on same interface
# ======================
IP_COUNT=$(ip addr show dev $INTERFACE | grep 'inet ' | wc -l)
if [ "$IP_COUNT" -gt 1 ]; then
  echo "$(date): Multiple IPs detected on $INTERFACE" >> "$LOG_DIR/ip_check.log"
fi

# ======================
# 5. Block PC-to-PC LAN access except gateway
# ======================
iptables -A OUTPUT -d $DEFAULT_GW -j ACCEPT
iptables -A OUTPUT -d ${SUBNET}.255 -j ACCEPT
iptables -A OUTPUT -d ${SUBNET}.0/24 -j DROP

# ======================
# 6. Detect foreign connections (no 127.0.0.1 or subnet)
# ======================
netstat -ntu | grep -v '127.0.0.1' | grep -v "${SUBNET}" >> "$LOG_DIR/foreign_conn.log"

# ======================
# 7. Disable Intel AMT interface if found
# ======================
if [ -d /sys/class/net/amt0 ]; then
  echo "$(date): AMT interface found - disabling" >> "$LOG_DIR/amt_check.log"
  ip link set amt0 down
fi
