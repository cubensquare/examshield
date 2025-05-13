#!/bin/bash
# Resets desktop environment while preserving hostname, URL, and static IP

PXE_USERNAME=$(logname)
USER_HOME="/home/$PXE_USERNAME"
LOGFILE="/var/log/reset-desktop.log"

echo "[i] Resetting desktop environment for $PXE_USERNAME" | tee -a $LOGFILE

# Clean XFCE session and cache
rm -rf "$USER_HOME/.cache"
rm -rf "$USER_HOME/.config/xfce4"
rm -rf "$USER_HOME/.config/session"

# Restore default panel and config if backed up
if [ -d "/etc/skel/.config" ]; then
  cp -r /etc/skel/.config "$USER_HOME"/
  chown -R "$PXE_USERNAME":"$PXE_USERNAME" "$USER_HOME/.config"
fi

# Ensure launcher file is intact (Firefox, Kiosk, etc.)
cp /etc/examshield/launch-firefox-kiosk.sh "$USER_HOME/Desktop/"
chmod +x "$USER_HOME/Desktop/launch-firefox-kiosk.sh"
chown "$PXE_USERNAME":"$PXE_USERNAME" "$USER_HOME/Desktop/launch-firefox-kiosk.sh"

# Restore ownership of home
chown -R "$PXE_USERNAME":"$PXE_USERNAME" "$USER_HOME"

echo "[✓] Desktop environment reset complete." | tee -a $LOGFILE
