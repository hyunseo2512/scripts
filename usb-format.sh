#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. 인자 확인
TARGET_DEV=$1

if [ -z "$TARGET_DEV" ]; then
    echo -e "${RED}오류: 장치명을 입력하세요. (예: ./usb-format.sh sda)${NC}"
    lsblk -p
    exit 1
fi

DEV_PATH="/dev/$TARGET_DEV"

# 2. 안전 장치: 시스템 드라이브 보호
if [[ "$TARGET_DEV" == "nvme0n1"* ]] || [[ "$TARGET_DEV" == "sda" && "$(lsblk -no MOUNTPOINTS $DEV_PATH | grep '/')" ]]; then
    echo -e "${RED}경고: $DEV_PATH 는 시스템 드라이브이거나 마운트된 상태입니다. 중단합니다.${NC}"
    exit 1
fi

echo -e "${YELLOW}경고: $DEV_PATH 의 모든 데이터가 삭제됩니다! (5초 후 시작)${NC}"
sleep 5

# 3. 마운트 해제
echo -e "${GREEN}[1/4] 마운트 해제 중...${NC}"
sudo umount ${DEV_PATH}* 2>/dev/null

# 4. 파일시스템 시그니처 강제 제거 (iso9660 잔상 제거)
echo -e "${GREEN}[2/4] 기존 시그니처 및 메타데이터 완전 제거...${NC}"
sudo wipefs -a $DEV_PATH

# 5. 파티션 테이블 생성 (GPT) 및 파티션 생성
echo -e "${GREEN}[3/4] GPT 파티션 테이블 및 새 파티션 생성 중...${NC}"
sudo parted -s $DEV_PATH mklabel gpt
sudo parted -s -a opt $DEV_PATH mkpart primary fat32 0% 100%

# 커널에 파티션 변경 사항 알림
sudo partprobe $DEV_PATH
sleep 2

# 6. FAT32 포맷
echo -e "${GREEN}[4/4] FAT32 파일시스템 포맷 중 (레이블: USB-DATA)...${NC}"
# 파티션 번호가 포함된 경로 (sda -> sda1, nvme0n1 -> nvme0n1p1 대응)
PART_PATH="${DEV_PATH}1"
if [[ "$DEV_PATH" == *"nvme"* ]]; then PART_PATH="${DEV_PATH}p1"; fi

sudo mkfs.vfat -F 32 -n "USB-DATA" $PART_PATH
