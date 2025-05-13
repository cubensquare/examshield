#!/bin/bash
# Purpose: Enforce strict launcher behavior and block unauthorized apps
# Applies to PXE client at boot via rc.local

PXE_USERNAME=$(logname)
USER_HOME="/home/$PXE_USERNAME"
ALLOWED_APPS=("firefox" "xfce4-terminal")  # Add more if required
LOGFILE="/var/log/launcher_restrictions.log"

echo "[i] Restricting applications on PXE client" | tee -a "$LOGFILE"

# Kill all user apps that aren't whitelisted
ps -u "$PXE_USERNAME" -o pid=,comm= | while read -r pid cmd; do
  if [[ ! " ${ALLOWED_APPS[@]} " =~ " $cmd " ]]; then
    echo "[!] Killing unauthorized app: $cmd (PID: $pid)" | tee -a "$LOGFILE"
    kill -9 "$pid" 2>/dev/null
  fi
done

# Lock Firefox to prevent new tabs or config changes
LOCK_PREFS_FILE=$(find "$USER_HOME/.mozilla/firefox" -name user.js | head -n 1)
mkdir -p "$(dirname "$LOCK_PREFS_FILE")"

cat <<EOF > "$LOCK_PREFS_FILE"
user_pref("browser.tabs.drawInTitlebar", false);
user_pref("browser.newtabpage.enabled", false);
user_pref("browser.tabs.warnOnClose", true);
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
EOF

chown "$PXE_USERNAME:$PXE_USERNAME" "$LOCK_PREFS_FILE"
chmod 644 "$LOCK_PREFS_FILE"

echo "[✓] Application restrictions applied at $(date)" | tee -a "$LOGFILE"
