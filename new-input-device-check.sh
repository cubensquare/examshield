#!/bin/bash

# Log file
LOG_FILE="/var/log/input_display_restrictions.log"
echo "[INFO] Device restriction check started at $(date)" > "$LOG_FILE"

# Allow only 1 keyboard and 1 mouse
KEYBOARD_COUNT=$(lsusb | grep -i keyboard | wc -l)
MOUSE_COUNT=$(lsusb | grep -i mouse | wc -l)
TOUCH_COUNT=$(lsusb | grep -i touch | wc -l)  # in case of touchpad/mouse combos

# Count display controllers (HDMI/VGA mostly on PCI)
DISPLAY_COUNT=$(lspci | grep -Ei 'vga|display' | wc -l)

# Allow only 1 each
[ "$KEYBOARD_COUNT" -gt 1 ] && echo "[ALERT] Multiple keyboards detected!" >> "$LOG_FILE"
[ "$MOUSE_COUNT" -gt 1 ] && echo "[ALERT] Multiple mice detected!" >> "$LOG_FILE"
[ "$TOUCH_COUNT" -gt 1 ] && echo "[ALERT] Multiple touch interfaces detected!" >> "$LOG_FILE"
[ "$DISPLAY_COUNT" -gt 1 ] && echo "[ALERT] Multiple display controllers (HDMI/VGA) detected!" >> "$LOG_FILE"

# Detect KVM switches
if lsusb | grep -i kvm > /dev/null; then
    echo "[ALERT] KVM switch detected via USB!" >> "$LOG_FILE"
fi

# Optional: Disable devices if needed
# You can add `unbind` logic for extra devices found via lsusb/lsinput

echo "[INFO] Device check completed at $(date)" >> "$LOG_FILE"
