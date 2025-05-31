#!/bin/bash

# Extract IP dynamically from kernel command line
PXE_SERVER_IP=$(cat /proc/cmdline | grep -oP 'pxe_server_ip=\K[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')

if [ -z "$PXE_SERVER_IP" ]; then
  echo "[!] PXE Server IP not found in /proc/cmdline" >> /var/log/examshield/launch_error.log
  exit 1
fi

# Generate the HTML file
cat <<EOF > /usr/local/bin/launch-wrapper.html
<!DOCTYPE html>
<html>
<head>
  <title>Exam Page</title>
  <script src="file:///usr/local/bin/disable-ui-functions.js"></script>
</head>
<frameset>
  <frame src="http://${PXE_SERVER_IP}/exam.html">
</frameset>
</html>
EOF

# Update permissions
chown examuser:examuser /usr/local/bin/launch-wrapper.html
chmod 644 /usr/local/bin/launch-wrapper.html
