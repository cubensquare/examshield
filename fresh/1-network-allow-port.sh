# Flush all existing rules
iptables -F

# Accept incoming HTTP, HTTPS, and ICMP only
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT

# Allow established connections (important)
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Set default policy to drop everything else
iptables -P INPUT DROP
iptables -P FORWARD DROP
