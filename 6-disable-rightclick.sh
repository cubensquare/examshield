#!/bin/bash
# disable-rightclick.sh

# Disable right-click globally
xinput --list | grep -i "mouse" | awk -F'id=' '{print $2}' | awk '{print $1}' | while read id; do
  xinput set-button-map "$id" 1 0 3 4 5 6 7
done
