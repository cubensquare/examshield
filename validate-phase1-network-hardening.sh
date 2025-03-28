#!/bin/bash

echo "===== Phase 1: Network Hardening & Internet Restrictions ====="
set -e

echo "[1/9] Installing iptables and persistent rules..."
apt update -y && apt install -y iptables iptables-persistent net-tools

echo "[2/9] Flushing existing rules and setting default policy..."
iptables -F
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

echo "[3/9] Allowing loopback and established sessions..."
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

echo "[4/9] Allowing PXE server IP (192.168.68.101) only for ports 80, 443, ICMP..."
iptables -A INPUT -s 192.168.68.101 -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -s 192.168.68.101 -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p icmp -s 192.168.68.101 --icmp-type echo-request -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -j DROP

echo "[5/9] Saving iptables rules for persistence..."
netfilter-persistent save

echo "[6/9] Setting local-only DNS to PXE server..."
echo "nameserver 192.168.68.101" > /etc/resolv.conf

echo "[7/9] Disabling default internet route..."
echo "ip route del default" >> /etc/rc.local
chmod +x /etc/rc.local

echo "[8/9] Configuring static IP in /etc/network/interfaces..."
cat <<EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
  address 192.168.68.150
  netmask 255.255.255.0
  gateway 192.168.68.1
EOF

echo "[9/9] Blacklisting Wi-Fi modules..."
cat <<EOF > /etc/modprobe.d/blacklist-wireless.conf
blacklist iwlwifi
blacklist rtl8187
blacklist brcmsmac
blacklist b43
blacklist rt2800usb
blacklist rtl8xxxu
EOF

echo "===== ✅ Phase 1 Complete ====="
echo "Expected Result:"
echo "✔ Internet access disabled"
echo "✔ Only PXE server can be pinged (192.168.68.101)"
echo "✔ Ports 80, 443 allowed from PXE only"
echo "✔ DHCP or other devices on LAN are blocked"
