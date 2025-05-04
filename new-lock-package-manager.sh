#!/bin/bash

# Path: /etc/network/lock-package-manager.sh

LOGFILE="/var/log/install_attempts.log"

# Disable apt commands by overriding
echo '[!] apt is disabled for this exam environment.' > /usr/local/bin/apt
echo '[!] dpkg is disabled for this exam environment.' > /usr/local/bin/dpkg
chmod +x /usr/local/bin/apt /usr/local/bin/dpkg

# Use aliases to trap attempts
echo "alias apt='echo [!] APT command is disabled >> $LOGFILE'" >> /etc/profile
echo "alias dpkg='echo [!] DPKG command is disabled >> $LOGFILE'" >> /etc/profile

# Ensure the original binaries are untouched but not accessible
chmod 000 /usr/bin/apt /usr/bin/dpkg

echo "[✓] Package installation disabled for PXE client."
