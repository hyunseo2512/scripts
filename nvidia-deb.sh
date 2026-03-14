#!/bin/bash

# 1. NVIDIA 그래픽 카드 확인
echo "Checking for NVIDIA GPU..."
if lspci | grep -i nvidia > /dev/null; then
    echo "NVIDIA GPU found."
else
    echo "NVIDIA GPU를 찾을 수 없습니다."
    exit 1
fi

# 2. 패키지 목록 업데이트
echo "Updating package lists..."
sudo apt update -y

# 3. 드라이버 추천 도구 설치
echo "Installing driver detection tool..."
sudo apt install -y ubuntu-drivers-common

# 4. 가장 적합한 드라이버 자동 설치
echo "Installing the recommended NVIDIA driver..."
sudo ubuntu-drivers autoinstall

# 5. 필수 의존성 및 빌드 도구 설치 (DKMS 포함)
sudo apt install -y dkms build-essential linux-headers-$(uname -r)

# 6. 완료 안내
echo "----------------------------------------------------"
echo "설치가 완료되었습니다. 변경 사항을 적용하려면 재부팅하세요."
echo "명령어: sudo reboot"
echo "재부팅 후 'nvidia-smi'로 확인 가능합니다."
echo "----------------------------------------------------"
