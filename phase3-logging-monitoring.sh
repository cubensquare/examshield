#!/bin/bash

echo "[INFO] Starting Phase 3: Logging & Monitoring Hardening..."

# Exit on error
set -e

### -------------------------------------------------
### 1. LOG USB INSERTIONS
### -------------------------------------------------
echo "[INFO] Setting up USB logging via udev..."

cat <<EOF > /etc/udev/rules.d/91-usb-log.rules
ACTION=="add", SUBSYSTEM=="usb", RUN+="/usr/bin/logger -t USB-Log 'USB device inserted: \$env{ID_SERIAL}'"
EOF

### -------------------------------------------------
### 2. LOG NETWORK CONNECTIONS PERIODICALLY
### -------------------------------------------------
echo "[INFO] Creating cron job to log active connections..."

cat <<EOF > /usr/local/bin/log-connections.sh
#!/bin/bash
ss -tunap > /var/log/connection-log_\$(date +%Y%m%d%H%M).log
EOF

chmod +x /usr/local/bin/log-connections.sh

# Set up cron job
echo "*/5 * * * * root /usr/local/bin/log-connections.sh" > /etc/cron.d/log-conn

### -------------------------------------------------
### 3. ALERT ON FOREIGN PC CONNECTION ATTEMPTS (Optional - basic)
### -------------------------------------------------
echo "[INFO] Setting up firewall log rule to detect foreign connections..."

iptables -A INPUT -s ! 192.168.68.0/24 -j LOG --log-prefix "FOREIGN_CONN_ATTEMPT: "

# Log rule is persistent
netfilter-persistent save

### -------------------------------------------------
### 4. ENABLE LOGGING TO FILE AND ROTATE
### -------------------------------------------------
echo "[INFO] Setting up logrotate for custom logs..."

cat <<EOF > /etc/logrotate.d/secure-custom
/var/log/connection-log_*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 root utmp
}
EOF

### -------------------------------------------------
### 5. SECURE LOG DIRECTORY
### -------------------------------------------------
echo "[INFO] Creating and protecting secure log directory..."

mkdir -p /var/log/secure-logs
chmod 700 /var/log/secure-logs
chown root:root /var/log/secure-logs

# Optional: symlink logs
ln -sf /var/log/connection-log_* /var/log/secure-logs/

### -------------------------------------------------
### 6. ENCRYPTED LOGGING (Optional basic setup)
### -------------------------------------------------
echo "[INFO] (Optional) Add rsyslog forwarding to another secure server or encrypt logs manually."

# Note: Advanced users can use journald+GPG or forward to external syslog with TLS.

### -------------------------------------------------
echo "[SUCCESS] Phase 3 Logging & Monitoring complete. Rebuild squashfs and test on PXE client."
