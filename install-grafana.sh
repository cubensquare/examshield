# 1. Install required packages
sudo apt-get update
sudo apt-get install -y gnupg2 curl software-properties-common

# 2. Add the Grafana GPG key (updated method)
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://packages.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null

# 3. Add Grafana repository securely using signed-by
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://packages.grafana.com/oss/deb stable main" | \
  sudo tee /etc/apt/sources.list.d/grafana.list

# 4. Update and install Grafana
sudo apt-get update
sudo apt-get install -y grafana

# 5. Enable and start Grafana
sudo systemctl enable grafana-server
sudo systemctl start grafana-server
