cat << 'EOF' > /usr/local/bin/map_exam_host.sh
#!/bin/bash
PXE_IP=$(ip route | grep -oP 'src \K[\d.]+' | head -n1)
grep -q "exam.local" /etc/hosts \
  && sed -i "s/.*exam\.local.*/$PXE_IP exam.local/" /etc/hosts \
  || echo "$PXE_IP exam.local" >> /etc/hosts
EOF

chmod +x /usr/local/bin/map_exam_host.sh
