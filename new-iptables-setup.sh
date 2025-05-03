#!/bin/bash
set -e

# Detect default interface (excluding loopback)
DEFAULT_IFACE=$(ip -o link show | awk -F': ' '$2 != "lo" {print $2; exit}')

# Flush existing rules
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X

# Set default policy to DROP
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow ICMP (ping)
iptables -A INPUT -p icmp --icmp-type 8 -j ACCEPT
iptables -A OUTPUT -p icmp -j ACCEPT

# Allow HTTP (port 80)
iptables -A INPUT -i "$DEFAULT_IFACE" -p tcp --dport 80 -j ACCEPT
iptables -A OUTPUT -o "$DEFAULT_IFACE" -p tcp --sport 80 -j ACCEPT

# Allow HTTPS (port 443)
iptables -A INPUT -i "$DEFAULT_IFACE" -p tcp --dport 443 -j ACCEPT
iptables -A OUTPUT -o "$DEFAULT_IFACE" -p tcp --sport 443 -j ACCEPT

# Save iptables rules
iptables-save > /etc/iptables/rules.v4
