wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
sudo apt install apt-transport-https
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-7.x.list
sudo apt update
sudo apt install elasticsearch
sudo systemctl enable --now elasticsearch

# Install kibana
sudo apt install kibana
sudo systemctl enable --now kibana

# Install logstash
sudo apt install logstash
