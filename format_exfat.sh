#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. 인자 확인
TARGET_DEV=$1

if [ -z "$TARGET_DEV" ]; then
    echo -e "${RED}오류: 장치명을 입력하세요. (예: ./usb-format.sh sdb)${NC}"
    lsblk -p
    exit 1
fi

DEV_PATH="/dev/$TARGET_DEV"

# 장치 존재 여부 확인
if [ ! -b "$DEV_PATH" ]; then
    echo -e "${RED}오류: $DEV_PATH 장치를 찾을 수 없습니다.${NC}"
    exit 1
fi

# 2. 안전 장치: 시스템 드라이브 및 마운트 상태 보호
# 현재 루트(/) 또는 /home이 포함된 장치인지 확인
if lsblk -no MOUNTPOINTS "$DEV_PATH" | grep -E '^(/|/home)$' > /dev/null; then
    echo -e "${RED}위험: $DEV_PATH 는 시스템 중요한 경로가 마운트된 드라이브입니다. 중단합니다.${NC}"
    exit 1
fi

echo -e "${YELLOW}경고: $DEV_PATH 의 모든 데이터가 삭제되고 exFAT(대용량 지원)로 포맷됩니다!${NC}"
echo -e "${YELLOW}5초 후 시작합니다... (취소: Ctrl+C)${NC}"
sleep 5

# 3. 필요한 패키지 확인 (Fedora 기준)
if ! command -v mkfs.exfat &> /dev/null; then
    echo -e "${YELLOW}exfatprogs 패키지가 필요합니다. 설치를 시도합니다...${NC}"
    sudo dnf install -y exfatprogs
fi

# 4. 마운트 해제
echo -e "${GREEN}[1/5] 마운트 해제 중...${NC}"
sudo umount ${DEV_PATH}* 2>/dev/null

# 5. 기존 시그니처 제거
echo -e "${GREEN}[2/5] 기존 파티션 정보 및 시그니처 완전 제거...${NC}"
sudo wipefs -a $DEV_PATH

# 6. GPT 파티션 테이블 및 파티션 생성
echo -e "${GREEN}[3/5] GPT 파티션 테이블 생성 및 전체 영역 할당...${NC}"
sudo parted -s $DEV_PATH mklabel gpt
sudo parted -s -a opt $DEV_PATH mkpart primary exfat 0% 100%

# 커널에 파티션 변경 알림 및 대기
sudo partprobe $DEV_PATH
sleep 2

# 7. 파티션 경로 설정
PART_PATH="${DEV_PATH}1"
if [[ "$DEV_PATH" == *"nvme"* ]]; then PART_PATH="${DEV_PATH}p1"; fi

# 8. exFAT 포맷 (대용량 파일 지원)
echo -e "${GREEN}[4/5] exFAT 파일시스템 포맷 중 (레이블: LARGE-DATA)...${NC}"
# -n: 레이블, -Q: 빠른 포맷
sudo mkfs.exfat -n "LARGE-DATA" $PART_PATH

# 9. 정리 및 완료
echo -e "${GREEN}[5/5] 동기화 중...${NC}"
sync

echo -e "${GREEN}완료! 이제 128GB 이상의 대용량 파일도 이 USB에 담을 수 있습니다.${NC}"
lsblk -f $DEV_PATH
