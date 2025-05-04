#!/bin/bash

LOGFILE="/var/log/blocked_install_attempts.log"
APT_CMD="/usr/bin/apt"
DPKG_CMD="/usr/bin/dpkg"

echo "[+] Disabling installation and updates..."

# Make apt and dpkg non-executable (won’t affect ISO build process if run at boot)
chmod -x "$APT_CMD" 2>/dev/null && echo "[✓] Disabled apt"
chmod -x "$DPKG_CMD" 2>/dev/null && echo "[✓] Disabled dpkg"

# Trap any attempt to run apt/dpkg and log it
cat << 'EOF' > /usr/local/bin/apt
#!/bin/bash
echo "$(date): Attempt to run apt $@" >> $LOGFILE
echo "Install blocked. This system is locked for exam mode."
exit 1
EOF

cat << 'EOF' > /usr/local/bin/dpkg
#!/bin/bash
echo "$(date): Attempt to run dpkg $@" >> $LOGFILE
echo "Install blocked. This system is locked for exam mode."
exit 1
EOF

chmod +x /usr/local/bin/apt /usr/local/bin/dpkg

# Ensure these override system binaries
export PATH="/usr/local/bin:$PATH"

echo "[✓] Installation and updates are blocked."
