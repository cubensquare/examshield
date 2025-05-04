#!/bin/bash

# Combined Firefox Kiosk Launcher Script for PXE Client

# Load PXE user config
if [ -f /etc/pxe-user.conf ]; then
  source /etc/pxe-user.conf
else
  PXE_USERNAME=$(logname)  # fallback if config missing
  echo "[!] /etc/pxe-user.conf not found. Using logged-in user: $PXE_USERNAME"
fi

echo "[i] Preparing Firefox for kiosk launch as user: $PXE_USERNAME"

# Cleanup any previous session locks to avoid startup issues
sudo -u "$PXE_USERNAME" rm -f /home/"$PXE_USERNAME"/.mozilla/firefox/*.default*/lock 2>/dev/null
sudo -u "$PXE_USERNAME" rm -f /home/"$PXE_USERNAME"/.mozilla/firefox/installs.ini 2>/dev/null
sudo -u "$PXE_USERNAME" rm -f /home/"$PXE_USERNAME"/.mozilla/firefox/profiles.ini 2>/dev/null

# Log path
LOGFILE="/var/log/firefox_kiosk_launch.log"

# Launch Firefox in kiosk mode
echo "[i] Launching Firefox in kiosk mode..." | tee -a "$LOGFILE"
sudo -u "$PXE_USERNAME" firefox --kiosk http://exam.local >> "$LOGFILE" 2>&1 &

# Final log
echo "[✓] Firefox kiosk launched at $(date)" | tee -a "$LOGFILE"
