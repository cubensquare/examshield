#!/bin/bash

METRIC_DIR="/var/lib/node_exporter"
mkdir -p "$METRIC_DIR"

IP=$(ip -o -4 addr show | awk '/inet/ && !/127.0.0.1/ {print $4}' | cut -d/ -f1 | head -n1)
MAC=$(cat /sys/class/net/$(ip route show default | awk '/default/ {print $5}')/address)
HOSTNAME=$(hostname)
MEMORY_TOTAL=$(grep MemTotal /proc/meminfo | awk '{print $2}')

echo "pxe_client_ip{ip=\"$IP\"} 1" > "$METRIC_DIR/pxe_client_ip.prom"
echo "pxe_client_mac{mac=\"$MAC\"} 1" > "$METRIC_DIR/pxe_client_mac.prom"
echo "pxe_client_hostname{name=\"$HOSTNAME\"} 1" > "$METRIC_DIR/pxe_client_hostname.prom"
echo "pxe_client_memory_kb $MEMORY_TOTAL" > "$METRIC_DIR/pxe_client_memory.prom"
EOF
