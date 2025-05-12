#!/bin/bash

# Simulate PXE metrics
mkdir -p /var/lib/node_exporter/
cat <<EOF > /var/lib/node_exporter/fake_exam.prom
exam_boot_status{mac="00:11:22:33:44:55", hostname="pxe-test1", ip="192.168.0.123"} 1
exam_memory_usage{mac="00:11:22:33:44:55", hostname="pxe-test1"} 42.3
EOF

# Simulate PXE logs for Filebeat → Kibana
mkdir -p /var/log/examshield
cat <<EOF >> /var/log/examshield/test_pxe.log
[INFO] [$(date '+%F %T')] PXE client booted: MAC=00:11:22:33:44:55, IP=192.168.0.123, Hostname=pxe-test1
[USB] [$(date '+%F %T')] USB inserted on /dev/sdb1
EOF

echo "[✓] PXE client activity simulated for Grafana and Kibana"
