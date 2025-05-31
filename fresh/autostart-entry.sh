mkdir -p /home/examuser/.config/autostart
cat <<EOF > /home/examuser/.config/autostart/network-harden.desktop
[Desktop Entry]
Type=Application
Exec=/usr/local/bin/network-harden.sh
Hidden=false
X-GNOME-Autostart-enabled=true
Name=Network Hardening
EOF

chown -R examuser:examuser /home/examuser/.config/autostart
