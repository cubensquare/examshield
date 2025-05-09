#!/bin/bash
set -e

echo "[+] Installing Filebeat in chroot..."

# 1. Create keyring directory
mkdir -p /etc/apt/keyrings

# 2. Download Elastic GPG key and store securely
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch \
  | gpg --dearmor -o /etc/apt/keyrings/elastic-archive-keyring.gpg

# 3. Add Elastic APT repository
echo "deb [signed-by=/etc/apt/keyrings/elastic-archive-keyring.gpg] https://artifacts.elastic.co/packages/7.x/apt stable main" \
  > /etc/apt/sources.list.d/elastic-7.x.list

# 4. Update package index
apt update

# 5. Install Filebeat
apt install filebeat -y

echo "[✓] Filebeat installed successfully."
