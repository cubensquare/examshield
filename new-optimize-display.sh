#!/bin/bash

echo "[i] Starting display optimization..."

# Auto-detect user
PXE_USERNAME=$(who | awk '{print $1}' | head -n 1)

# === Set screen resolution to optimal (example: 1024x768)
xrandr_output=$(xrandr | grep ' connected' | awk '{print $1}')
export DISPLAY=:0
export XAUTHORITY="/home/$PXE_USERNAME/.Xauthority"
sudo -u "$PXE_USERNAME" xrandr --output "$xrandr_output" --mode 1024x768

# === Set full brightness (assuming backlight is available)
BACKLIGHT_PATH=$(find /sys/class/backlight -type d | head -n 1)
if [[ -n "$BACKLIGHT_PATH" ]]; then
  echo $(cat "$BACKLIGHT_PATH/max_brightness") > "$BACKLIGHT_PATH/brightness"
  echo "[✓] Brightness set to maximum"
fi

# === Disable screen blanking and lock timeout
sudo -u "$PXE_USERNAME" xset s off
sudo -u "$PXE_USERNAME" xset -dpms
sudo -u "$PXE_USERNAME" xset s noblank

# Disable XFCE Power Manager timeout settings (if XFCE is used)
if [ -f /home/$PXE_USERNAME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-power-manager.xml ]; then
  sed -i 's/<property name="blank-on-ac" type="int" value=".*"\/>/<property name="blank-on-ac" type="int" value="0"\/>/g' /home/$PXE_USERNAME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-power-manager.xml
fi

echo "[✓] Display optimization completed"
