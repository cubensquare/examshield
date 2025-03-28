#!/bin/bash

echo "[INFO] Starting Phase 1: Network Hardening..."

# Exit on error
set -e

echo "[INFO] Installing iptables and persistent rules..."
apt update
apt install -y iptables iptables-persistent

echo "[INFO] Configuring iptables rules..."

# Flush existing
iptables -F
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow loopback and existing connections
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow HTTP and HTTPS from PXE server
iptables -A INPUT -s 192.168.68.101 -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -s 192.168.68.101 -p tcp --dport 443 -j ACCEPT

# ICMP ping only from PXE server
iptables -A INPUT -p icmp -s 192.168.68.101 --icmp-type echo-request -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -j DROP

# Save rules
netfilter-persistent save

echo "[INFO] Blocking external DNS and Internet..."
echo "nameserver 192.168.68.101" > /etc/resolv.conf
echo "ip route del default" >> /etc/rc.local
chmod +x /etc/rc.local

echo "[INFO] Disabling NetworkManager and setting static IP..."
systemctl disable NetworkManager || true

cat <<EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
  address 192.168.68.150
  netmask 255.255.255.0
  gateway 192.168.68.1
EOF

echo "[INFO] Creating check_ips.sh for monitoring multiple IPs..."
cat <<EOF > /usr/local/bin/check_ips.sh
#!/bin/bash
ip -4 addr | grep inet | grep -v lo | wc -l > /tmp/ip_count.txt
EOF
chmod +x /usr/local/bin/check_ips.sh

echo "[INFO] Blacklisting Wi-Fi modules..."
cat <<EOF > /etc/modprobe.d/blacklist-wireless.conf
blacklist iwlwifi
blacklist rtl8187
blacklist brcmsmac
blacklist b43
blacklist rt2800usb
blacklist rtl8xxxu
EOF

echo "[INFO] Creating udev rule to log USB insertions..."
cat <<EOF > /etc/udev/rules.d/99-usb-block.rules
ACTION=="add", SUBSYSTEM=="usb", RUN+="/usr/bin/logger -p local0.warn USB device inserted"
EOF

echo "[INFO] Blacklisting USB mass storage..."
echo "blacklist usb-storage" > /etc/modprobe.d/usbblock.conf

echo "[SUCCESS] Phase 1 hardening complete. Rebuild squashfs and test on PXE client."
