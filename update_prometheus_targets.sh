#!/bin/bash

PROM_FILE="/etc/prometheus/prometheus.yml"
TMP_FILE="/tmp/prometheus_new.yml"

# Auto-detect PXE subnet from default interface IP
PXE_IFACE=$(ip route | awk '/default/ {print $5}')
PXE_SUBNET=$(ip -4 addr show $PXE_IFACE | grep -oP '(?<=inet\s)\d+(\.\d+){3}/\d+')
PXE_BASE=$(echo "$PXE_SUBNET" | cut -d'.' -f1-3)

# Begin Prometheus config
cat <<EOF > $TMP_FILE
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node_exporters'
    static_configs:
      targets:
EOF

# Scan for active PXE clients on port 9100
for ip in $(seq 2 254); do
  TARGET_IP="$PXE_BASE.$ip"
  if nc -z -w1 $TARGET_IP 9100 2>/dev/null; then
    echo "        - '$TARGET_IP:9100'" >> $TMP_FILE
  fi
done

# Replace and restart
mv $TMP_FILE $PROM_FILE
systemctl restart prometheus

echo "[✓] Prometheus configuration updated with live PXE clients on $PXE_BASE.0/24"
