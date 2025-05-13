#!/bin/bash

# Load username
PXE_USERNAME=$(logname)
USER_HOME="/home/$PXE_USERNAME"

echo "[i] Customizing XFCE Desktop Menu for user: $PXE_USERNAME"

# 1. Create custom desktop entries
mkdir -p "$USER_HOME/.local/share/applications"

# View Exam
cat <<EOF > "$USER_HOME/.local/share/applications/view-exam.desktop"
[Desktop Entry]
Name=View Exam
Comment=Launch exam browser
Exec=firefox http://exam.local
Icon=web-browser
Terminal=false
Type=Application
Categories=Custom;
EOF

# Node Details
cat <<EOF > "$USER_HOME/.local/share/applications/node-details.desktop"
[Desktop Entry]
Name=Node Details
Comment=Show node system info
Exec=/usr/local/bin/show-node-info.sh
Icon=dialog-information
Terminal=false
Type=Application
Categories=Custom;
EOF

chmod +x "$USER_HOME/.local/share/applications/"*.desktop
chown -R "$PXE_USERNAME:$PXE_USERNAME" "$USER_HOME/.local/share/applications"

# 2. Create the popup script
cat <<'EOF' > /usr/local/bin/show-node-info.sh
#!/bin/bash
PXE_USERNAME=$(logname)
IFACE=$(ip route | awk '/default/ {print $5}')
IP=$(ip -4 addr show "$IFACE" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
MAC=$(cat /sys/class/net/"$IFACE"/address)
HOSTNAME=$(hostname)
INFO="Hostname: $HOSTNAME\nIP Address: $IP\nMAC Address: $MAC"

export DISPLAY=:0
export XAUTHORITY="/home/$PXE_USERNAME/.Xauthority"
sudo -u "$PXE_USERNAME" zenity --info --title="Node Info" --text="$INFO"
EOF

chmod +x /usr/local/bin/show-node-info.sh

# 3. Remove logout/shutdown etc
sudo -u "$PXE_USERNAME" mkdir -p "$USER_HOME/.config/xfce4/xfconf/xfce-perchannel-xml"
PANEL_XML="$USER_HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml"

# Backup existing panel config
cp -f "$PANEL_XML" "$PANEL_XML.bak" 2>/dev/null || true

# Disable logout buttons by filtering panel config
sed -i '/<property name="items">/,/<\/property>/ {
  /logout/,/lock-screen/d
}' "$PANEL_XML"

# 4. Filter Whisker Menu / App Menu to only Custom category
MENU_XML="$USER_HOME/.config/xfce4/panel/whiskermenu-1.rc"
mkdir -p "$(dirname $MENU_XML)"
cat <<EOF > "$MENU_XML"
whiskermenu
{
  category_filter {
    Custom
  }
}
EOF

chown -R "$PXE_USERNAME:$PXE_USERNAME" "$USER_HOME/.config"

# 5. Kill panel to reload config
sudo -u "$PXE_USERNAME" xfce4-panel --restart

echo "[✓] Custom PXE client desktop applied."
