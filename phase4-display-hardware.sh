#!/bin/bash

echo "[INFO] Starting Phase 4: Display & Hardware Security Hardening..."

# Exit on error
set -e

### -------------------------------------------------
### 1. DISABLE HDMI, VGA, OTHER VIDEO OUTPUTS (if detected)
### -------------------------------------------------
echo "[INFO] Disabling HDMI/VGA video output using xrandr (runtime)..."

cat <<'EOF' > /usr/local/bin/disable-video-outputs.sh
#!/bin/bash
xrandr | grep " connected" | grep -v eDP | cut -d" " -f1 | while read display; do
  xrandr --output "$display" --off
done
EOF

chmod +x /usr/local/bin/disable-video-outputs.sh

# Add to autostart
mkdir -p /home/goms/.config/autostart
cat <<EOF > /home/goms/.config/autostart/disable-video.desktop
[Desktop Entry]
Type=Application
Exec=/usr/local/bin/disable-video-outputs.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Disable Extra Displays
EOF

chown -R goms:goms /home/goms/.config/autostart

### -------------------------------------------------
### 2. SET FIXED RESOLUTION, MAX BRIGHTNESS
### -------------------------------------------------
echo "[INFO] Enforcing screen resolution and brightness..."

cat <<'EOF' > /usr/local/bin/set-resolution-brightness.sh
#!/bin/bash
xrandr --output eDP-1 --mode 1366x768 || true
echo 100 > /sys/class/backlight/intel_backlight/brightness 2>/dev/null || true
EOF

chmod +x /usr/local/bin/set-resolution-brightness.sh

# Add to autostart
cat <<EOF > /home/goms/.config/autostart/display-config.desktop
[Desktop Entry]
Type=Application
Exec=/usr/local/bin/set-resolution-brightness.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Set Display Settings
EOF

### -------------------------------------------------
### 3. DISABLE SCREENSAVER AND LOCK SCREEN
### -------------------------------------------------
echo "[INFO] Disabling screensaver and auto-lock..."

mkdir -p /home/goms/.config/xfce4/xfconf/xfce-perchannel-xml
cat <<EOF > /home/goms/.config/xfce4/xfconf/xfce-perchannel-xml/xscreensaver.xml
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfce4-screensaver" version="1.0">
  <property name="lock-enabled" type="bool" value="false"/>
  <property name="idle-activation-enabled" type="bool" value="false"/>
</channel>
EOF

chown -R goms:goms /home/goms/.config

### -------------------------------------------------
### 4. SHOW SYSTEM INFO ON SCREEN (hostname, MAC, IP)
### -------------------------------------------------
echo "[INFO] Creating desktop info overlay..."

cat <<'EOF' > /usr/local/bin/show-sysinfo.sh
#!/bin/bash
IP=$(hostname -I | awk '{print $1}')
MAC=$(cat /sys/class/net/eth0/address)
HOST=$(hostname)

xmessage -center "HOST: $HOST  |  IP: $IP  |  MAC: $MAC" &
EOF

chmod +x /usr/local/bin/show-sysinfo.sh

cat <<EOF > /home/goms/.config/autostart/sysinfo.desktop
[Desktop Entry]
Type=Application
Exec=/usr/local/bin/show-sysinfo.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=System Info Popup
EOF

### -------------------------------------------------
### 5. AUTOHIDE TOOLBAR AND FORCE FULLSCREEN (Xfce)
### -------------------------------------------------
echo "[INFO] Autohiding toolbar..."

mkdir -p /home/goms/.config/xfce4/xfconf/xfce-perchannel-xml
cat <<EOF > /home/goms/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfce4-panel" version="1.0">
  <property name="panels" type="array">
    <value type="int" value="1"/>
  </property>
  <property name="panel-1" type="empty">
    <property name="autohide" type="bool" value="true"/>
    <property name="position" type="string" value="p=6;x=0;y=0"/>
  </property>
</channel>
EOF

chown -R goms:goms /home/goms/.config

### -------------------------------------------------
echo "[SUCCESS] Phase 4 Display & Hardware Lockdown complete. Rebuild squashfs and test on PXE client."
