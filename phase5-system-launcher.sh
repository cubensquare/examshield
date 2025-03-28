#!/bin/bash

echo "[INFO] Starting Phase 5: Persistence, Launcher Lockdown & Whitelisting..."

set -e

### -------------------------------------------------
### 1. STATIC HOSTNAME & HOST FILE
### -------------------------------------------------
echo "[INFO] Setting static hostname and hosts file..."

hostnamectl set-hostname exam-os
echo "127.0.0.1   localhost" > /etc/hosts
echo "192.168.68.150   exam-os" >> /etc/hosts

### -------------------------------------------------
### 2. STATIC IP PRESERVATION (Already in Phase 1)
### -------------------------------------------------
# Reconfirm /etc/network/interfaces
echo "[INFO] Re-confirming static IP setup..."
cat <<EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
  address 192.168.68.150
  netmask 255.255.255.0
  gateway 192.168.68.1
EOF

### -------------------------------------------------
### 3. ENFORCE LAUNCHER URL LOCKDOWN
### -------------------------------------------------
echo "[INFO] Enforcing locked launcher (Firefox kiosk with fixed URL)..."

# (Already created in Phase 2, just ensure it's locked down here too)
# Additional: Remove Firefox address bar & dev tools via policies
mkdir -p /etc/firefox/policies
cat <<EOF > /etc/firefox/policies/policies.json
{
  "policies": {
    "Homepage": {
      "StartPage": "http://192.168.68.101/index.html",
      "Locked": true
    },
    "DisablePrivateBrowsing": true,
    "DisableDeveloperTools": true,
    "DisplayBookmarksToolbar": false,
    "DisableFirefoxAccounts": true,
    "DisableFormHistory": true,
    "DisableSystemAddonUpdate": true,
    "DisableProfileImport": true,
    "DisableTelemetry": true
  }
}
EOF

### -------------------------------------------------
### 4. WHITELIST PROGRAMS – BLOCK ALL OTHERS
### -------------------------------------------------
echo "[INFO] Whitelisting Firefox, disabling all other GUI apps..."

mkdir -p /usr/local/bin/allowed-apps
ln -s /usr/bin/firefox /usr/local/bin/allowed-apps/firefox

cat <<EOF > /etc/profile.d/whitelist.sh
#!/bin/bash
export PATH="/usr/local/bin/allowed-apps"
EOF
chmod +x /etc/profile.d/whitelist.sh

# Optional: Clean up other .desktop files
rm -f /usr/share/applications/*.desktop
cp /usr/share/applications/firefox.desktop /usr/share/applications/

### -------------------------------------------------
### 5. DISABLE VM DETECTION (Prevent execution inside VM)
### -------------------------------------------------
echo "[INFO] Adding script to detect & block virtual machines..."

cat <<'EOF' > /usr/local/bin/vm-check.sh
#!/bin/bash
if grep -qE '(vmware|qemu|kvm|vbox)' /proc/cpuinfo || \
   systemd-detect-virt | grep -vq "none"; then
   echo "This OS cannot be run inside a virtual machine."
   poweroff
fi
EOF

chmod +x /usr/local/bin/vm-check.sh

# Add to autostart
cat <<EOF > /home/goms/.config/autostart/vmcheck.desktop
[Desktop Entry]
Type=Application
Exec=/usr/local/bin/vm-check.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=VM Check
EOF

### -------------------------------------------------
### 6. DISABLE CTRL+ALT+DEL REBOOT KEY
### -------------------------------------------------
echo "[INFO] Disabling Ctrl+Alt+Del keybinding..."

rm -f /etc/systemd/system/ctrl-alt-del.target
ln -sf /dev/null /etc/systemd/system/ctrl-alt-del.target

### -------------------------------------------------
### 7. BLOCK ALL PACKAGE MANAGERS (if not done already)
### -------------------------------------------------
echo "[INFO] Blocking apt and related tools (double check)..."
chmod -x /usr/bin/apt || true
chmod -x /usr/bin/apt-get || true
chmod -x /usr/bin/dpkg || true

### -------------------------------------------------
### 8. CREATE LOCAL CONFIG BACKUP
### -------------------------------------------------
echo "[INFO] Saving critical config in /opt/exam-config-backup..."

mkdir -p /opt/exam-config-backup
cp /etc/hostname /opt/exam-config-backup/
cp /etc/network/interfaces /opt/exam-config-backup/
cp /etc/firefox/policies/policies.json /opt/exam-config-backup/
cp /etc/profile.d/whitelist.sh /opt/exam-config-backup/

### -------------------------------------------------
echo "[SUCCESS] Phase 5: System Persistence & Launcher Restrictions Complete."
echo ">> Rebuild squashfs and PXE boot to validate final behavior."
