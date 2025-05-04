#!/bin/bash

# Load PXE user config
source /etc/pxe-user.conf

echo "[i] Launching Firefox in kiosk mode..."
sudo -u "$PXE_USERNAME" firefox --kiosk http://exam.local &
