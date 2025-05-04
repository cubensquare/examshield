#!/bin/bash
# Encrypt logs for tamper-proof auditing

LOG_SRC="/var/log/keystroke_block.log"
LOG_ENCRYPTED="/var/log/keystroke_block.log.enc"
PUBLIC_KEY="/etc/security/pubkey.pem"   # Add your public key here

if [ -f "$LOG_SRC" ] && [ -f "$PUBLIC_KEY" ]; then
  openssl rsautl -encrypt -inkey "$PUBLIC_KEY" -pubin -in "$LOG_SRC" -out "$LOG_ENCRYPTED"
  echo "[✓] Log encrypted at $LOG_ENCRYPTED"
else
  echo "[✗] Missing log or public key"
fi
