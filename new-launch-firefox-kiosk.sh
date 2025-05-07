#!/bin/bash

# Enhanced Firefox Kiosk Launcher with Lockdown

# Load PXE user config
if [ -f /etc/pxe-user.conf ]; then
  source /etc/pxe-user.conf
else
  PXE_USERNAME=$(logname)  # fallback if config missing
  echo "[!] /etc/pxe-user.conf not found. Using logged-in user: $PXE_USERNAME"
fi

echo "[i] Preparing Firefox for kiosk launch as user: $PXE_USERNAME"

# Clean any Firefox leftover locks
sudo -u "$PXE_USERNAME" rm -f /home/"$PXE_USERNAME"/.mozilla/firefox/*.default*/lock 2>/dev/null
sudo -u "$PXE_USERNAME" rm -f /home/"$PXE_USERNAME"/.mozilla/firefox/installs.ini 2>/dev/null
sudo -u "$PXE_USERNAME" rm -f /home/"$PXE_USERNAME"/.mozilla/firefox/profiles.ini 2>/dev/null

# Kill alternate panels or shell launchers
echo "[i] Killing system panels and alternate launchers..."
pkill -f xfce4-panel
pkill -f lxpanel
pkill -f gnome-shell
pkill -f mate-panel
pkill -f openbox
pkill -f dock
pkill -f plank

# Optional: hide mouse pointer if needed (install unclutter if required)
command -v unclutter >/dev/null && unclutter &

# Log file
LOGFILE="/var/log/firefox_kiosk_launch.log"
echo "[i] Launching Firefox in kiosk mode..." | tee -a "$LOGFILE"
sudo -u "$PXE_USERNAME" firefox --kiosk http://exam.local >> "$LOGFILE" 2>&1 &

# Monitor & enforce: restart if closed
(
  while true; do
    if ! pgrep -u "$PXE_USERNAME" firefox >/dev/null; then
      echo "[!] Firefox was closed! Relaunching..." | tee -a "$LOGFILE"
      sudo -u "$PXE_USERNAME" firefox --kiosk http://exam.local >> "$LOGFILE" 2>&1 &
    fi
    sleep 5
  done
) &

echo "[✓] Firefox kiosk launched and being monitored at $(date)" | tee -a "$LOGFILE"
