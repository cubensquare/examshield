#!/bin/bash

# Get PXE client user
PXE_USERNAME=$(logname)
USER_HOME="/home/$PXE_USERNAME"

# Set DISPLAY & XAUTHORITY
export DISPLAY=:0
export XAUTHORITY="$USER_HOME/.Xauthority"

echo "[i] Disabling screensaver and DPMS for user: $PXE_USERNAME"

# Disable Xfce screensaver if installed
sudo -u "$PXE_USERNAME" xfconf-query -c xfce4-session -p /general/LockCommand -n -t string -s ""
sudo -u "$PXE_USERNAME" xfconf-query -c xfce4-session -p /shutdown/LockScreen -n -t bool -s false

# Disable xscreensaver if installed
sudo -u "$PXE_USERNAME" xscreensaver-command -exit 2>/dev/null || true

# Prevent blanking and power saving
xset s off           # Disable screen saver
xset -dpms           # Disable DPMS (Energy Star)
xset s noblank       # Don't blank the video device

# Log settings
xset q | grep -A2 "Screen Saver"

echo "[✓] Screensaver and display power saving disabled."
