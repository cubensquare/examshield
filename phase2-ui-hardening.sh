#!/bin/bash

echo "[INFO] Starting Phase 2: User & UI Restrictions Hardening..."

# Exit on error
set -e

### -------------------------------------------------
### 1. AUTOLOGIN SETUP (if not already done)
### -------------------------------------------------
echo "[INFO] Configuring autologin for user 'goms'..."

mkdir -p /etc/lightdm
cat <<EOF > /etc/lightdm/lightdm.conf
[Seat:*]
autologin-user=goms
autologin-user-timeout=0
user-session=xfce
EOF

### -------------------------------------------------
### 2. FIREFOX IN KIOSK MODE WITH TEST PAGE
### -------------------------------------------------
echo "[INFO] Setting Firefox to kiosk mode on boot..."

mkdir -p /home/goms/.config/autostart
cat <<EOF > /home/goms/.config/autostart/firefox-kiosk.desktop
[Desktop Entry]
Type=Application
Exec=firefox --kiosk http://192.168.68.101/index.html
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Exam Launcher
EOF

chown -R goms:goms /home/goms/.config

### -------------------------------------------------
### 3. DISABLE PACKAGE INSTALLATION & UPDATES
### -------------------------------------------------
echo "[INFO] Blocking apt and package installations..."

chmod -x /usr/bin/apt
chmod -x /usr/bin/apt-get
chmod -x /usr/bin/dpkg
echo "readonly PATH" >> /etc/profile

### -------------------------------------------------
### 4. DISABLE RESTART, SHUTDOWN, SLEEP
### -------------------------------------------------
echo "[INFO] Disabling power controls (shutdown, suspend, reboot)..."

mkdir -p /etc/polkit-1/localauthority/50-local.d/
cat <<EOF > /etc/polkit-1/localauthority/50-local.d/disable-power.pkla
[Disable Power Options]
Identity=unix-user:*
Action=org.freedesktop.login1.* 
ResultActive=no
EOF

### -------------------------------------------------
### 5. BLOCK SPECIAL KEYS (CTRL, ALT, DEL, etc.)
### -------------------------------------------------
echo "[INFO] Blocking keyboard shortcuts..."

cat <<EOF > /usr/share/xsessions/disable-keys.desktop
[Desktop Entry]
Name=DisableKeys
Exec=setxkbmap -option
Type=Application
EOF

cat <<EOF > /etc/profile.d/disable-keys.sh
#!/bin/bash
xmodmap -e "keycode 133 = NoSymbol"  # Super/Win key
xmodmap -e "keycode 37 = NoSymbol"   # Ctrl
xmodmap -e "keycode 64 = NoSymbol"   # Alt
xmodmap -e "keycode 107 = NoSymbol"  # Print Screen
xmodmap -e "keycode 115 = NoSymbol"  # Menu
EOF

chmod +x /etc/profile.d/disable-keys.sh

### -------------------------------------------------
### 6. DISABLE RIGHT-CLICK (XFCE ONLY)
### -------------------------------------------------
echo "[INFO] Disabling right-click..."

mkdir -p /home/goms/.config/xfce4/xfconf/xfce-perchannel-xml
cat <<EOF > /home/goms/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
<?xml version="1.0" encoding="UTF-8"?>

<channel name="xfce4-desktop" version="1.0">
  <property name="desktop-menu" type="bool" value="false"/>
</channel>
EOF

chown -R goms:goms /home/goms/.config/xfce4

### -------------------------------------------------
### 7. PREVENT MULTIPLE TABS, FORCE FULLSCREEN
### -------------------------------------------------
echo "[INFO] Enforcing fullscreen browser and tab restrictions..."

cat <<EOF > /etc/firefox/policies/policies.json
{
  "policies": {
    "DisablePrivateBrowsing": true,
    "DisableDeveloperTools": true,
    "DisableFirefoxAccounts": true,
    "DisableForgetButton": true,
    "DisableFormHistory": true,
    "DisableMasterPasswordCreation": true,
    "DisablePocket": true,
    "DisableProfileImport": true,
    "DisableSafeMode": true,
    "DisableSystemAddonUpdate": true,
    "DisableTelemetry": true,
    "DisableAccounts": true,
    "Homepage": {
      "StartPage": "http://192.168.68.101/index.html",
      "Locked": true
    },
    "PopupBlocking": {
      "Locked": true
    }
  }
}
EOF

### -------------------------------------------------
echo "[SUCCESS] Phase 2 UI/User Lockdown complete. Rebuild squashfs and test on PXE client."
