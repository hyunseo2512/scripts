#!/bin/bash

# 1. NVIDIA 그래픽 카드 하드웨어 확인
echo "Checking for NVIDIA GPU..."
GPU_CHECK=$(lspci | grep -i nvidia)

if [ -z "$GPU_CHECK" ]; then
    echo "NVIDIA GPU를 찾을 수 없습니다. 하드웨어 연결을 확인하세요."
    exit 1
else
    echo "GPU 발견: $GPU_CHECK"
fi

# 2. 시스템 업데이트 및 필수 패키지 설치
echo "Updating system and installing dependencies..."
dnf update -y
dnf install -y kernel-devel kernel-headers gcc make elfutils-libelf-devel libglvnd-devel

# 3. EPEL 및 NVIDIA CUDA 저장소 추가
echo "Adding NVIDIA repositories..."
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(rpm -E %rhel).noarch.rpm
DISTRO="rhel$(rpm -E %rhel | cut -d. -f1)"
ARCH=$(uname -m)
dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/$DISTRO/$ARCH/cuda-$DISTRO.repo

# 4. 기존 Nouveau 드라이버 비활성화 (충돌 방지)
echo "Disabling Nouveau driver..."
echo "blacklist nouveau" > /etc/modprobe.d/blacklist-nouveau.conf
echo "options nouveau modeset=0" >> /etc/modprobe.d/blacklist-nouveau.conf
dracut --force

# 5. NVIDIA 드라이버 설치
echo "Installing NVIDIA driver..."
dnf module install -y nvidia-driver:latest-dkms

# 6. 완료 및 재부팅 안내
echo "----------------------------------------------------"
echo "설치가 완료되었습니다. 변경 사항을 적용하려면 시스템을 재부팅해야 합니다."
echo "재부팅 후 'nvidia-smi' 명령어로 설치 상태를 확인하세요."
echo "----------------------------------------------------"
