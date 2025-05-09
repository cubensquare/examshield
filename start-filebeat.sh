#!/bin/bash

# Set PXE server IP dynamically and start Filebeat
PXE_SERVER_IP=$(ip route | awk '/default/ {print $3}')
export PXE_SERVER_IP

# Replace environment variable in config
envsubst < /etc/filebeat/filebeat.yml.template > /etc/filebeat/filebeat.yml

# Start Filebeat
systemctl restart filebeat
