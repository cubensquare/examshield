#!/bin/bash

PROM_FILE="/etc/prometheus/prometheus.yml"
TMP_FILE="/tmp/prometheus_new.yml"

# Detect default network interface
PXE_IFACE=$(ip route | awk '/default/ {print $5}')
PXE_SUBNET=$(ip -4 addr show $PXE_IFACE | awk '/inet / {print $2}')
PXE_BASE=$(echo "$PXE_SUBNET" | cut -d'.' -f1-3)

# Start config file
cat <<EOF > "$TMP_FILE"
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node_exporters'
    static_configs:
      - targets: [
EOF

# Scan PXE clients and build targets list
FIRST=true
for ip in $(seq 2 254); do
  TARGET="$PXE_BASE.$ip"
  if nc -z -w1 $TARGET 9100 2>/dev/null; then
    if [ "$FIRST" = true ]; then
      echo "          \"$TARGET:9100\"" >> "$TMP_FILE"
      FIRST=false
    else
      echo "          ,\"$TARGET:9100\"" >> "$TMP_FILE"
    fi
  fi
done

# Close list and finalize file
echo "        ]" >> "$TMP_FILE"

# Validate and apply
if promtool check config "$TMP_FILE"; then
  mv "$TMP_FILE" "$PROM_FILE"
  systemctl restart prometheus
  echo "[✓] Prometheus config updated with PXE clients on ${PXE_BASE}.0/24"
else
  echo "[!] Prometheus config invalid. Skipping update."
  rm -f "$TMP_FILE"
fi
