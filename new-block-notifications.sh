#!/bin/bash

LOGFILE="/var/log/alien_device_detected.log"

echo "[+] Disabling desktop/system notifications..."

# Disable known notification services
pkill -f notify-osd 2>/dev/null
pkill -f notification-daemon 2>/dev/null

# Mask notify-osd if exists
[ -f /usr/lib/notify-osd/notify-osd ] && chmod -x /usr/lib/notify-osd/notify-osd

# Optional: suppress dbus/systemd user notifications
gsettings set org.gnome.desktop.notifications show-banners false 2>/dev/null
gsettings set org.gnome.desktop.notifications show-in-lock-screen false 2>/dev/null

echo "[✓] Notifications disabled (system/user)."

# Begin alien device detection (USB NICs or storage devices)
echo "[+] Monitoring for unauthorized USB devices..."

inotifywait -m /dev -e create |
while read path action file; do
    if [[ "$file" == sd* || "$file" == video* || "$file" == ttyUSB* ]]; then
        echo "[!] Alien device detected: $file at $(date)" | tee -a "$LOGFILE"
        wall "ALERT: Unauthorized device detected: $file"
    fi
done &
