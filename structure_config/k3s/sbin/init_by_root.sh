#!/bin/bash

# forked from https://raw.githubusercontent.com/soerenmetje/k3s-rootless/refs/heads/master/setup-preparation.sh

set -x # Print each command before execution
set -e # fail and abort script if one command fails
set -o pipefail

# Install dependencies -------------------------------------------
apt update && apt install -y uidmap fuse3

# Configure machine features -------------------------------------------

# Enabling cgroup v2
if grep -q "GRUB_CMDLINE_LINUX=\".*systemd.unified_cgroup_hierarchy=1.*\"" /etc/default/grub; then
  echo "cgroup v2 entry already exists. Skipping..."
else
  # Sed line in /etc/default/grub
  sed -i 's/GRUB_CMDLINE_LINUX="\(.*\)"/GRUB_CMDLINE_LINUX="\1 systemd.unified_cgroup_hierarchy=1"/' /etc/default/grub
  echo "cgroup v2 was enabled in /etc/default/grub"
fi

update-grub

# Enable CPU, CPUSET, and I/O delegation work
mkdir -p /etc/systemd/system/user@.service.d

if [ -f "/etc/systemd/system/user@.service.d/delegate.conf" ]; then
  echo "Delegation file already exist. Skipping..."
else
  cat <<EOF | tee /etc/systemd/system/user@.service.d/delegate.conf
[Service]
Delegate=cpu cpuset io memory pids
EOF
  echo "Delegation file was added"
fi

systemctl daemon-reload

# Check if line already exists in /etc/sysctl.conf
if grep -q -e "^\s*net\.ipv4\.ip_forward=1" /etc/sysctl.conf; then
  echo "IP forwarding already exists in /etc/sysctl.conf . Skipping..."
else
  # Add the line to /etc/sysctl.conf
  echo "net.ipv4.ip_forward=1" | tee -a /etc/sysctl.conf
  echo "IP forwarding was added to /etc/sysctl.conf"
fi

# Enable IP forwarding
sysctl -w net.ipv4.ip_forward=1

echo "IP forwarding is enabled"