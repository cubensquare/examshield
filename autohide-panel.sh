#!/bin/bash

LOGFILE="/var/log/autohide-panel.log"
echo "[i] Starting XFCE panel autohide script..." | tee -a "$LOGFILE"

# Detect active graphical user (who owns :0 display)
PXE_USERNAME=$(who | awk '{print $1}' | head -n 1)

if [ -z "$PXE_USERNAME" ]; then
  echo "[!] Could not detect logged-in user. Exiting." | tee -a "$LOGFILE"
  exit 1
fi

echo "[i] Detected user: $PXE_USERNAME" | tee -a "$LOGFILE"

# Set display environment
export DISPLAY=:0
export XAUTHORITY="/home/$PXE_USERNAME/.Xauthority"

# Wait for XFCE to finish initializing
sleep 5

# Get panel ID (typically 1)
PANEL_ID=$(sudo -u "$PXE_USERNAME" xfconf-query -c xfce4-panel -l | grep "autohide" | sed 's|/autohide||;s|/panels/||')

if [ -z "$PANEL_ID" ]; then
  echo "[!] Could not determine panel ID. Aborting." | tee -a "$LOGFILE"
  exit 1
fi

# Set autohide mode: 2 = always hide
sudo -u "$PXE_USERNAME" xfconf-query -c xfce4-panel -p "/panels/$PANEL_ID/autohide" -n -t int -s 2

echo "[✓] XFCE panel $PANEL_ID set to always autohide for $PXE_USERNAME" | tee -a "$LOGFILE"
