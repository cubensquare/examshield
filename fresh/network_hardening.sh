#!/bin/bash
# Secure PXE Chroot with Network Isolation and Enforcement
# Run on PXE SERVER HOST (not in chroot)

# Configuration
CHROOT_PATH="/path/to/your/chroot"  # CHANGE THIS
LOG_DIR="/var/log/secure_pxe"
RULES_DIR="/etc/secure_pxe_rules"
NAMESPACE="pxe_ns_$(date +%s)"
VETH_HOST="veth_host_$(hostname)"
VETH_CHROOT="veth_chroot_$(hostname)"

# Initialize environment
mkdir -p "$LOG_DIR" "$RULES_DIR"
exec > >(tee -a "$LOG_DIR/secure_pxe_$(date +%Y%m%d).log") 2>&1

# 1. DYNAMIC NETWORK ISOLATION
create_secure_network() {
    echo "=== SECURE NETWORK INITIALIZATION ==="
    
    # Detect host network
    HOST_IFACE=$(ip route show default | awk '/default/ {print $5}')
    HOST_IP=$(ip -4 addr show dev "$HOST_IFACE" | awk '/inet/ {print $2}' | cut -d'/' -f1)
    
    # Generate isolated network
    ISOLATED_SUBNET="10.$((RANDOM%240+10)).$((RANDOM%240+10)).0/24"
    ISOLATED_HOST="${ISOLATED_SUBNET%.0/24}.1"
    ISOLATED_CHROOT="${ISOLATED_SUBNET%.0/24}.2"
    TEST_SERVER_IP="$HOST_IP"  # Default to host IP as test server
    
    echo "[*] Network Configuration:"
    echo "    Host Interface: $HOST_IFACE"
    echo "    Test Server IP: $TEST_SERVER_IP"
    echo "    Isolated Subnet: $ISOLATED_SUBNET"
    echo "    Chroot IP: $ISOLATED_CHROOT"
    
    # Create namespace
    ip netns add "$NAMESPACE"
    
    # Create veth pair
    ip link add "$VETH_HOST" type veth peer name "$VETH_CHROOT"
    ip link set "$VETH_CHROOT" netns "$NAMESPACE"
    
    # Configure host side
    ip addr add "$ISOLATED_HOST/24" dev "$VETH_HOST"
    ip link set "$VETH_HOST" up
    
    # Configure namespace side
    ip netns exec "$NAMESPACE" ip addr add "$ISOLATED_CHROOT/24" dev "$VETH_CHROOT"
    ip netns exec "$NAMESPACE" ip link set "$VETH_CHROOT" up
    ip netns exec "$NAMESPACE" ip route add default via "$ISOLATED_HOST"
    
    # Enable controlled NAT
    echo 1 > /proc/sys/net/ipv4/ip_forward
    iptables -t nat -A POSTROUTING -s "$ISOLATED_SUBNET" -d "$TEST_SERVER_IP" -j MASQUERADE
}

# 2. SECURITY ENFORCEMENT
apply_security_rules() {
    echo "=== APPLYING SECURITY RULES ==="
    
    # 1. Allow only ports 443, 80, and ICMP (ping)
    ip netns exec "$NAMESPACE" iptables -F
    ip netns exec "$NAMESPACE" iptables -P INPUT DROP
    ip netns exec "$NAMESPACE" iptables -P OUTPUT DROP
    ip netns exec "$NAMESPACE" iptables -P FORWARD DROP
    
    # Allow loopback
    ip netns exec "$NAMESPACE" iptables -A INPUT -i lo -j ACCEPT
    ip netns exec "$NAMESPACE" iptables -A OUTPUT -o lo -j ACCEPT
    
    # Allow HTTP/HTTPS only to test server
    ip netns exec "$NAMESPACE" iptables -A OUTPUT -d "$TEST_SERVER_IP" -p tcp --dport 80 -j ACCEPT
    ip netns exec "$NAMESPACE" iptables -A OUTPUT -d "$TEST_SERVER_IP" -p tcp --dport 443 -j ACCEPT
    ip netns exec "$NAMESPACE" iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    
    # 2. Allow ping only to test server
    ip netns exec "$NAMESPACE" iptables -A OUTPUT -d "$TEST_SERVER_IP" -p icmp --icmp-type echo-request -j ACCEPT
    ip netns exec "$NAMESPACE" iptables -A INPUT -d "$ISOLATED_CHROOT" -p icmp --icmp-type echo-reply -j ACCEPT
    
    # 3. Block all other internet access
    ip netns exec "$NAMESPACE" iptables -A OUTPUT -j DROP
    
    # 4. Single LAN IP enforcement
    ip netns exec "$NAMESPACE" iptables -A INPUT -i "$VETH_CHROOT" ! -s "$TEST_SERVER_IP" -j LOG --log-prefix "UNAUTHORIZED_LAN_ACCESS: "
    ip netns exec "$NAMESPACE" iptables -A INPUT -i "$VETH_CHROOT" ! -s "$TEST_SERVER_IP" -j DROP
    
    # 5. Prevent multiple IPs on interface
    ip netns exec "$NAMESPACE" ip link set "$VETH_CHROOT" promisc off
    
    # 6. Disable Wi-Fi and data cards (namespace only)
    ip netns exec "$NAMESPACE" rfkill block all 2>/dev/null
    
    # 7. Block PC-to-PC communication
    ip netns exec "$NAMESPACE" iptables -A FORWARD -j DROP
    
    # 8. Periodic connection monitoring
    (while true; do
        ip netns exec "$NAMESPACE" netstat -ntu | grep -Ev "(127.0.0.1|$TEST_SERVER_IP)" >> "$LOG_DIR/foreign_conn_$(date +%Y%m%d).log"
        sleep 30
    done) &
    
    # 9. AMT detection and disable
    if ip netns exec "$NAMESPACE" [ -d /sys/class/net/amt0 ]; then
        echo "[!] AMT detected - disabling" | tee -a "$LOG_DIR/amt.log"
        ip netns exec "$NAMESPACE" ip link set amt0 down
    fi
    
    # 10. Configuration change monitoring
    inotifywait -m "$RULES_DIR" "$LOG_DIR" -e create,modify,delete 2>/dev/null | while read; do
        echo "Configuration change detected: $REPLY" >> "$LOG_DIR/config_changes.log"
    done &
}

# 3. CHROOT LAUNCHER
launch_secure_chroot() {
    echo "=== LAUNCHING SECURE CHROOT ==="
    
    # Mount required filesystems
    mount --make-private --rbind /dev  "$CHROOT_PATH/dev"
    mount --make-private --rbind /proc "$CHROOT_PATH/proc"
    mount --make-private --rbind /sys  "$CHROOT_PATH/sys"
    
    # Start secure environment
    ip netns exec "$NAMESPACE" \
        chroot "$CHROOT_PATH" /bin/bash -c "
            # Environment hardening
            echo '=== SECURE ENVIRONMENT ==='
            echo 'Allowed IP: $TEST_SERVER_IP'
            echo 'Available Ports: 80, 443, ICMP(ping)'
            echo 'Network Monitoring Active'
            
            # Your exam environment initialization
            /bin/bash --noprofile --norc
        "
}

# 4. CLEANUP
cleanup() {
    echo "=== SECURE CLEANUP ==="
    
    # Kill all background processes
    pkill -P $$ 2>/dev/null
    
    # Remove network namespace
    ip netns del "$NAMESPACE" 2>/dev/null
    
    # Clean iptables
    iptables -t nat -D POSTROUTING -s "$ISOLATED_SUBNET" -d "$TEST_SERVER_IP" -j MASQUERADE 2>/dev/null
    
    # Unmount filesystems
    umount -R "$CHROOT_PATH"/{dev,proc,sys} 2>/dev/null
    
    echo "[✓] All secure resources released" | tee -a "$LOG_DIR/session_$(date +%s).log"
}

# Main execution
trap cleanup EXIT INT TERM
create_secure_network
apply_security_rules
launch_secure_chroot

# Keep session alive
while true; do sleep 3600; done
