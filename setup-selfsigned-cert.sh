#!/bin/bash

# Configuration
DOMAIN="exam.local"
CERT_DIR="/etc/ssl/exam"
KEY_FILE="$CERT_DIR/exam.key"
CERT_FILE="$CERT_DIR/exam.crt"
TRUSTED_CERT="/usr/local/share/ca-certificates/exam.crt"
LOGFILE="/var/log/selfsigned-cert.log"

mkdir -p "$CERT_DIR"

# Generate self-signed certificate if not exists
if [ ! -f "$CERT_FILE" ]; then
  echo "[i] Generating self-signed certificate for $DOMAIN" | tee -a "$LOGFILE"
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$KEY_FILE" \
    -out "$CERT_FILE" \
    -subj "/CN=$DOMAIN" >> "$LOGFILE" 2>&1

  # Trust the certificate
  cp "$CERT_FILE" "$TRUSTED_CERT"
  update-ca-certificates >> "$LOGFILE" 2>&1
  echo "[✓] Certificate installed and trusted."
else
  echo "[i] Certificate already exists, skipping generation." | tee -a "$LOGFILE"
fi
