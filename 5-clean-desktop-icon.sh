#!/bin/bash
# Purpose: Remove all default desktop icons from XFCE Desktop environment

echo "[i] Cleaning desktop icons..."

PXE_USER=$(awk -F: '/\/home/ {print $1}' /etc/passwd | head -n 1)
USER_HOME="/home/$PXE_USER"

# Remove common desktop launchers if they exist
rm -f "$USER_HOME/Desktop/"*.desktop 2>/dev/null
rm -f "$USER_HOME/Desktop/"* 2>/dev/null

# Clean up desktop entries from skel (used during ISO build)
rm -f /etc/skel/Desktop/*.desktop 2>/dev/null
rm -f /etc/skel/Desktop/* 2>/dev/null

# Disable mounted devices, trash, and home folder from XFCE desktop
mkdir -p "$USER_HOME/.config/xfce4/desktop/"
cat <<EOF > "$USER_HOME/.config/xfce4/desktop/icons.settings"
[Desktop Icons]
show-trash=false
show-home=false
show-volumes=false
EOF

# Apply the same for skel (future default user copy)
mkdir -p /etc/skel/.config/xfce4/desktop/
cp "$USER_HOME/.config/xfce4/desktop/icons.settings" /etc/skel/.config/xfce4/desktop/icons.settings

chown -R "$PXE_USER":"$PXE_USER" "$USER_HOME/.config"
echo "[✓] Desktop icons removed and disabled."
