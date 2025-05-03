#!/bin/bash
# Description: Ensure each DHCP-assigned interface has only one IP address

LOG_FILE="/var/log/ipcheck.log"
echo "[*] Validating IP assignments..." | tee -a $LOG_FILE

interfaces=$(ip -o link show | awk -F': ' '$2 != "lo" {print $2}')

for iface in $interfaces; do
  # Check if the interface is up and has DHCP-assigned IP
  ip_count=$(ip -4 addr show "$iface" | grep -c 'inet ')
  
  if [ "$ip_count" -gt 1 ]; then
    echo "[!] Interface $iface has multiple IPs ($ip_count assigned)" | tee -a $LOG_FILE
    # Keep only the first assigned IP
    ip -4 addr show "$iface" | grep 'inet ' | awk 'NR>1 {print $2}' | while read -r ip; do
      ip addr del "$ip" dev "$iface"
      echo "[+] Removed extra IP: $ip from $iface" | tee -a $LOG_FILE
    done
  elif [ "$ip_count" -eq 1 ]; then
    echo "[✓] $iface has correct IP assigned from DHCP." | tee -a $LOG_FILE
  else
    echo "[!] $iface has NO IP. DHCP may have failed." | tee -a $LOG_FILE
  fi
done
