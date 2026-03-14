#!/bin/bash

# 색상 정의 (출력 가독성용)
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}>>> 가상화 환경 및 네트워크 최적화 설정을 시작합니다...${NC}"

# 1. 가상화 필수 패키지 설치
echo -e "${GREEN}[1/5] 가상화 패키지 그룹 설치 중...${NC}"
sudo dnf install -y @virtualization virt-manager qemu-guest-agent

# 2. 사용자 권한 설정 (로그아웃 후 적용됨)
echo -e "${GREEN}[2/5] 사용자 그룹 권한 추가 (libvirt)...${NC}"
sudo usermod -aG libvirt $(whoami)

# 3. IPv4 포워딩 영구 활성화 (커널 설정)
echo -e "${GREEN}[3/5] 커널 패킷 포워딩 설정 중...${NC}"
sudo mkdir -p /etc/sysctl.d
echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/99-kvm-forward.conf
sudo sysctl -p /etc/sysctl.d/99-kvm-forward.conf

# 4. 방화벽(firewalld) 규칙 설정 (Docker 충돌 방지 및 NAT 허용)
echo -e "${GREEN}[4/5] 방화벽(firewalld) 정책 설정 중...${NC}"
# 방화벽이 꺼져있을 수 있으므로 시작
sudo systemctl enable --now firewalld

# libvirt 영역 설정 및 인터페이스 추가
sudo firewall-cmd --permanent --zone=libvirt --add-interface=virbr0
sudo firewall-cmd --permanent --zone=public --add-masquerade

# Direct Rule 추가 (Docker의 DROP 정책보다 우선순위를 높임)
sudo firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -i virbr0 -j ACCEPT
sudo firewall-cmd --permanent --direct --add-rule ipv4 filter FORWARD 0 -o virbr0 -j ACCEPT

# 방화벽 리로드
sudo firewall-cmd --reload

# 5. 가상 네트워크 서비스 시작 및 자동실행
echo -e "${GREEN}[5/5] 가상 네트워크(default) 서비스 활성화...${NC}"
sudo systemctl enable --now libvirtd
sudo virsh net-autostart default 2>/dev/null || echo "Info: default network already autostarts"
sudo virsh net-start default 2>/dev/null || echo "Info: default network already started"

echo -e "${BLUE}--------------------------------------------------${NC}"
echo -e "${GREEN}설치가 완료되었습니다!${NC}"
echo -e "사용자 권한 적용을 위해 ${BLUE}로그아웃 후 다시 로그인${NC}하거나 ${BLUE}reboot${NC} 해주세요."
echo -e "${BLUE}--------------------------------------------------${NC}"
