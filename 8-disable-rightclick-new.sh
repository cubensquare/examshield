cat <<EOF > ~/squashfs-root/home/pxeuser/.config/autostart/disable-rightclick.desktop
[Desktop Entry]
Type=Application
Exec=/etc/network/disable-rightclick.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Disable Right Click
EOF
