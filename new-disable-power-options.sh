#!/bin/bash

LOGFILE="/var/log/power_action_blocked.log"
echo "[+] Disabling shutdown, reboot, sleep, standby, and logout options..."

# 1. Mask system services
systemctl mask poweroff.target reboot.target halt.target suspend.target sleep.target hibernate.target hybrid-sleep.target

# 2. Override binaries with wrapper
for cmd in shutdown reboot poweroff halt systemctl; do
  if [ -x "/usr/bin/$cmd" ]; then
    mv "/usr/bin/$cmd" "/usr/bin/${cmd}.bak"
    echo -e "#!/bin/bash\necho '[!] Power command $cmd blocked. Logged.' >> \"$LOGFILE\"" > "/usr/bin/$cmd"
    chmod +x "/usr/bin/$cmd"
  fi
done

# 3. Disable GUI shutdown/logout (for GNOME-based environments)
which gsettings &>/dev/null && {
  gsettings set org.gnome.desktop.lockdown disable-log-out true
  gsettings set org.gnome.desktop.lockdown disable-user-switching true
  gsettings set org.gnome.settings-daemon.plugins.power active false
  gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'nothing'
}

# 4. Kill logout/shutdown menu (XFCE/LXDE workaround - rename logout binaries if found)
if [ -f /usr/bin/lxsession-logout ]; then
  mv /usr/bin/lxsession-logout /usr/bin/lxsession-logout.disabled
fi

echo "[✓] Power options blocked."
