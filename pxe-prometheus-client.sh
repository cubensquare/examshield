#!/bin/bash

PXE_IP=$(ip route | awk '/default/ {print $3}')
PXE_USERNAME=$(logname)
METRICS_FILE="/var/lib/node_exporter/pxe_metrics.prom"
mkdir -p /var/lib/node_exporter

while true; do
  echo "# HELP pxe_client_info PXE client basic details" > "$METRICS_FILE"
  echo "# TYPE pxe_client_info gauge" >> "$METRICS_FILE"
  echo "pxe_client_info{mac=\"$(cat /sys/class/net/$(ip route | awk '/default/ {print $5}')/address)\", ip=\"$(hostname -I | awk '{print $1}')\", hostname=\"$(hostname)\"} 1" >> "$METRICS_FILE"

  echo "# HELP pxe_client_memory_used Memory used in MB" >> "$METRICS_FILE"
  echo "# TYPE pxe_client_memory_used gauge" >> "$METRICS_FILE"
  MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
  echo "pxe_client_memory_used $MEM_USED" >> "$METRICS_FILE"

  sleep 15
done &
