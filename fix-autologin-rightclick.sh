#!/bin/bash

set -e

echo "✅ Creating user goms if not exists..."
adduser --disabled-password --gecos "" goms || true
echo "goms:goms" | chpasswd

echo "✅ Installing LightDM..."
apt update
apt install -y lightdm

echo "✅ Setting LightDM as default..."
echo "/usr/sbin/lightdm" > /etc/X11/default-display-manager

echo "✅ Configuring LightDM autologin..."
mkdir -p /etc/lightdm/lightdm.conf.d
cat <<EOF > /etc/lightdm/lightdm.conf.d/50-autologin.conf
[Seat:*]
autologin-user=goms
autologin-user-timeout=0
user-session=xfce
EOF

echo "✅ Cleaning old Xauthority files..."
rm -f /home/goms/.Xauthority
rm -f /var/lib/lightdm/.Xauthority

echo "✅ Setting correct ownership..."
chown -R goms:goms /home/goms

echo "✅ Disabling right-click with xmodmap..."
cat <<EOF > /home/goms/.xsessionrc
#!/bin/bash
xmodmap -e "pointer = 1 0 3 4 5 6 7"
EOF

chmod +x /home/goms/.xsessionrc
chown goms:goms /home/goms/.xsessionrc

mkdir -p /home/goms/.config/autostart
cat <<EOF > /home/goms/.config/autostart/disable-rightclick.desktop
[Desktop Entry]
Type=Application
Name=Disable Right Click
Exec=/home/goms/.xsessionrc
X-GNOME-Autostart-enabled=true
EOF

chown -R goms:goms /home/goms/.config

echo "✅ Done. Please rebuild the squashfs and test again in PXE client."
