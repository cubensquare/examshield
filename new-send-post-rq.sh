curl -X POST http://<PXE_SERVER_IP>:5000/register \
     -H "Content-Type: application/json" \
     -d '{
           "mac": "'$(cat /sys/class/net/eth0/address)'",
           "ip": "'$(hostname -I | awk "{print \$1}")'",
           "hostname": "'$(hostname)'",
           "status": "booted"
         }'
