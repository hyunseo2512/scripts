#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# 1. Install Packages (APT)
echo -e "${GREEN}[1/5] Installing packages (KVM, Libvirt, UFW)...${NC}"
sudo apt update
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager ufw

# 2. User Permissions
# On Debian/Mint, the group is usually 'libvirt', but sometimes 'kvm' is also needed
sudo usermod -aG libvirt $(whoami)
sudo usermod -aG kvm $(whoami)

# 3. IPv4 Forwarding
echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/99-kvm-forward.conf
sudo sysctl -p /etc/sysctl.d/99-kvm-forward.conf

# 4. UFW Configuration
echo -e "${GREEN}[4/5] Configuring UFW routing and masquerading...${NC}"

# 4-1. Change Default Forward Policy
sudo sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw

# 4-2. NAT (Masquerade) Rules
if ! sudo grep -q "*nat" /etc/ufw/before.rules; then
    # We use a temp file because inserting at the top (1i) of before.rules 
    # can sometimes mess up header comments in Debian
    sudo sed -i '1i # KVM NAT Rules\n*nat\n:POSTROUTING ACCEPT [0:0]\n-A POSTROUTING -s 192.168.122.0/24 -j MASQUERADE\nCOMMIT\n' /etc/ufw/before.rules
fi

# 4-3. Allow Rules
sudo ufw allow ssh
sudo ufw allow in on virbr0
sudo ufw allow out on virbr0

# 5. Service Activation
echo -e "${GREEN}[5/5] Activating services and virtual network...${NC}"
sudo systemctl enable --now ufw
sudo systemctl enable --now libvirtd
sudo ufw --force enable

# Ensure the default network is active
sudo virsh net-autostart default 2>/dev/null
sudo virsh net-start default 2>/dev/null

echo -e "${BLUE}--------------------------------------------------${NC}"
echo -e "${GREEN}KVM setup for Linux Mint is complete.${NC}"
echo -e "${RED}Note: Please log out and log back in for group changes to work.${NC}"
echo -e "${BLUE}--------------------------------------------------${NC}"
