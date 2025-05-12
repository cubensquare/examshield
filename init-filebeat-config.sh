#!/bin/bash

# Dynamically determine PXE server IP from default route
PXE_SERVER_IP=$(ip route | awk '/default/ {print $3}')

TEMPLATE_FILE="/etc/filebeat/filebeat.yml.template"
FINAL_FILE="/etc/filebeat/filebeat.yml"

# Replace placeholder with actual PXE server IP
sed "s|__PXE_SERVER_IP__|$PXE_SERVER_IP|" "$TEMPLATE_FILE" > "$FINAL_FILE"

# Restart filebeat to use updated config
systemctl restart filebeat
