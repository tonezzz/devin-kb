#!/bin/bash
set -euo pipefail

# Post-install script to run on the notebook after the first USB boot.
# Configures a portable Ubuntu Desktop with Chrome, remote access, and your apps.
# Run this directly on the notebook, or from this PC via:
#   ssh youruser@<notebook-ip> 'bash -s' < post-install.sh

REMOTE_USER="${USER}"
NOTEBOOK_IP="${1:-}"

if [ -n "$NOTEBOOK_IP" ]; then
  echo "Usage on notebook: bash ./post-install.sh"
  echo "This script is meant to run directly on the notebook."
  echo "To run from this PC: ssh $REMOTE_USER@$NOTEBOOK_IP 'bash -s' < post-install.sh"
fi

# List your additional apps here. Examples:
# ADDITIONAL_APPS="slack discord telegram-desktop vlc gimp"
ADDITIONAL_APPS=""

echo "=== Updating system ==="
sudo apt update
sudo apt upgrade -y

echo "=== Installing basic tools ==="
sudo apt install -y \
  curl \
  git \
  htop \
  net-tools \
  vim \
  wget \
  unzip \
  rsync \
  ca-certificates \
  gnupg \
  lsb-release \
  apt-transport-https \
  software-properties-common

echo "=== Installing Google Chrome ==="
CHROME_DEB="/tmp/google-chrome-stable_current_amd64.deb"
if [ ! -f "$CHROME_DEB" ]; then
  wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O "$CHROME_DEB"
fi
sudo apt install -y "$CHROME_DEB" || sudo apt-get -f install -y

if [ -n "$ADDITIONAL_APPS" ]; then
  echo "=== Installing additional apps ==="
  sudo apt install -y $ADDITIONAL_APPS
fi

echo "=== Remote access and configuration ==="
# Ensure SSH is installed and running for remote config from this PC.
sudo apt install -y openssh-server
sudo systemctl enable ssh
sudo systemctl start ssh

# Install x11vnc for remote desktop access.
sudo apt install -y x11vnc

# Uncomment the following lines to disable password authentication and root login.
# Only do this after you have confirmed SSH key login works.
# sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
# sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
# sudo systemctl restart ssh

echo "=== Optional: Docker ==="
# Uncomment to install Docker for development containers.
# for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
#   sudo apt-get remove -y "$pkg" 2>/dev/null || true
# done
# sudo install -m 0755 -d /etc/apt/keyrings
# sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
# sudo chmod a+r /etc/apt/keyrings/docker.asc
# echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
# sudo apt update
# sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# sudo usermod -aG docker "$USER"
# sudo systemctl enable docker
# sudo systemctl start docker

echo "=== Optional: Tailscale for remote access ==="
# Uncomment to install Tailscale. You will need to authenticate with `sudo tailscale up`.
# curl -fsSL https://tailscale.com/install.sh | sh

echo "=== Optional: WireGuard tools ==="
# Uncomment if you prefer WireGuard over Tailscale.
# sudo apt install -y wireguard-tools

echo "=== Remote assistance setup ==="
# This notebook is configured for remote help from the Devin/Cascade IDE on this PC.
# SSH and x11vnc are installed above. No separate Devin IDE agent needs to be installed.
# You can connect from this PC via SSH, then continue working with the IDE in that terminal.

echo "=== Summary ==="
echo "Hostname: $(hostname)"
echo "IP addresses:"
ip -brief addr show
if command -v google-chrome &> /dev/null; then
  echo "Chrome version: $(google-chrome --version)"
fi
if command -v docker &> /dev/null; then
  echo "Docker version: $(docker --version)"
fi
echo ""
echo "Next steps:"
echo "1. Copy your dotfiles and profiles from this PC to the notebook."
echo "2. Set a VNC password if using x11vnc: x11vnc -storepasswd"
echo "3. From this PC, connect via SSH: ssh $REMOTE_USER@<notebook-ip>"
echo "4. For remote desktop, start x11vnc on the notebook: x11vnc -forever -usepw -display :0"
