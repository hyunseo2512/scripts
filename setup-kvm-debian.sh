#!/bin/bash

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}>>> [UFW 환경] 가상화 및 네트워크 설정을 시작합니다...${NC}"

# 1. 패키지 설치
echo -e "${GREEN}[1/5] 패키지 설치 (ufw 포함)...${NC}"
sudo dnf install -y @virtualization virt-manager ufw

# 2. 사용자 권한
sudo usermod -aG libvirt $(whoami)

# 3. IPv4 포워딩 활성화 (커널 레벨)
echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/99-kvm-forward.conf
sudo sysctl -p /etc/sysctl.d/99-kvm-forward.conf

# 4. UFW 상세 설정
echo -e "${GREEN}[4/5] UFW 라우팅 및 마스커레이딩 설정 중...${NC}"

# 4-1. UFW 기본 포워딩 정책을 ACCEPT로 변경
sudo sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw

# 4-2. NAT(마스커레이딩) 규칙 추가
# 이미 규칙이 있는지 확인 후 없으면 삽입
if ! sudo grep -q "*nat" /etc/ufw/before.rules; then
    sudo sed -i '1i # KVM NAT 규칙\n*nat\n:POSTROUTING ACCEPT [0:0]\n-A POSTROUTING -s 192.168.122.0/24 -j MASQUERADE\nCOMMIT\n' /etc/ufw/before.rules
fi

# 4-3. 기본 허용 규칙 (SSH 등 방어)
sudo ufw allow ssh
sudo ufw allow in on virbr0
sudo ufw allow out on virbr0

# 5. 서비스 활성화
echo -e "${GREEN}[5/5] 서비스 활성화 및 가상 네트워크 시작...${NC}"
sudo systemctl enable --now ufw
sudo systemctl enable --now libvirtd
sudo ufw --force enable

sudo virsh net-autostart default 2>/dev/null
sudo virsh net-start default 2>/dev/null

echo -e "${BLUE}--------------------------------------------------${NC}"
echo -e "${GREEN}UFW 기반 가상화 설정이 완료되었습니다.${NC}"
echo -e "${RED}경고: ufw는 잘못 설정하면 외부 접속이 차단될 수 있으니 주의하세요.${NC}"
echo -e "${BLUE}--------------------------------------------------${NC}"
