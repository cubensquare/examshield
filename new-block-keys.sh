#!/bin/bash
# Block specific keys during PXE client session
LOG_FILE="/var/log/keystroke_block.log"

echo "[i] Blocking keys..." | tee -a "$LOG_FILE"

# Ensure X is running before xmodmap
export DISPLAY=:0
export XAUTHORITY=/home/$(logname)/.Xauthority

# Create key mapping config
cat <<EOF > /etc/custom.xmodmap
remove control = Control_L Control_R
remove mod1 = Alt_L Alt_R
remove mod4 = Super_L Super_R
keycode  9 = NoSymbol    # ESC
keycode  66 = NoSymbol   # CAPS LOCK
keycode  107 = NoSymbol  # Menu
keycode  115 = NoSymbol  # Windows key / Super
keycode  110 = NoSymbol  # Home
keycode  115 = NoSymbol  # End
keycode  111 = NoSymbol  # PrintScreen
keycode  113 = NoSymbol  # Ctrl (left)
keycode  114 = NoSymbol  # Ctrl (right)
keycode  64 = NoSymbol   # Alt (left)
keycode  108 = NoSymbol  # Alt (right)
EOF

# Apply the keymap
xmodmap /etc/custom.xmodmap >> "$LOG_FILE" 2>&1

# Detect if any blocking failed
if [ $? -eq 0 ]; then
  echo "[✓] Key blocking applied." | tee -a "$LOG_FILE"
else
  echo "[✗] Key blocking failed." | tee -a "$LOG_FILE"
fi
