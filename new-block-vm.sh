#!/bin/bash

# Check for virtualization (QEMU, KVM, VMware, VirtualBox)
if grep -qa hypervisor /proc/cpuinfo || \
   systemd-detect-virt | grep -qiE 'kvm|qemu|vmware|virtualbox|xen'; then
    echo "[!] Virtual Machine detected. PXE Client is not allowed to run in VM."
    logger "[!] VM detected. Blocking PXE Client."
    wall "VM Detected! This PXE client cannot be used inside a Virtual Machine. Contact Administrator."
    sleep 5
    poweroff
fi
