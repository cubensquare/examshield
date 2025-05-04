#!/bin/bash

# Load PXE user config
source /etc/pxe-user.conf

echo "[i] Setting up Firefox kiosk..."

LOCKDOWN_PROFILE="$PXE_HOME/.mozilla/firefox/lockdown"
mkdir -p "$LOCKDOWN_PROFILE"

cat > "$LOCKDOWN_PROFILE/user.js" <<EOF
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("browser.tabs.warnOnClose", false);
user_pref("browser.tabs.warnOnOpen", false);
user_pref("browser.fullscreen.autohide", false);
user_pref("browser.fullscreen.animate", false);
user_pref("browser.link.open_newwindow", 1);
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.sessionstore.resume_from_crash", false);
user_pref("browser.startup.homepage", "http://exam.local");
user_pref("browser.startup.page", 1);
user_pref("startup.homepage_welcome_url", "");
user_pref("startup.homepage_welcome_url.additional", "");
EOF

chown -R "$PXE_USERNAME:$PXE_USERNAME" "$LOCKDOWN_PROFILE"
echo "[✓] Firefox lockdown config complete."
