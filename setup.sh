#!/bin/bash
# =============================================
# Browserless 초기 설정 스크립트
# =============================================

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Browserless 초기 설정${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# 디렉토리 생성
echo -e "${YELLOW}[1/5] 디렉토리 생성...${NC}"
mkdir -p downloads data
echo -e "${GREEN}✓ downloads/, data/ 디렉토리 생성 완료${NC}"
echo

# .env 파일 확인 및 생성
echo -e "${YELLOW}[2/5] 환경 설정 파일 확인...${NC}"
if [ -f .env ]; then
    echo -e "${YELLOW}⚠ .env 파일이 이미 존재합니다. 덮어쓰시겠습니까? (y/N)${NC}"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}기존 .env 파일 유지${NC}"
    else
        cp .env.example .env
        echo -e "${GREEN}✓ .env 파일 생성 완료${NC}"
    fi
else
    cp .env.example .env
    echo -e "${GREEN}✓ .env 파일 생성 완료${NC}"
fi
echo

# 토큰 생성
echo -e "${YELLOW}[3/5] 보안 토큰 생성...${NC}"

# OpenSSL로 토큰 생성 (가장 안전)
if command -v openssl &> /dev/null; then
    TOKEN=$(openssl rand -base64 32 | tr -d '/+=' | cut -c1-32)
# /dev/urandom 사용 (Linux/WSL)
elif [ -f /dev/urandom ]; then
    TOKEN=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
# date + $RANDOM 사용 (마지막 대안)
else
    TOKEN=$(date +%s%N | sha256sum | base64 | head -c 32)
fi

echo -e "${GREEN}✓ 생성된 토큰: ${NC}${BLUE}${TOKEN}${NC}"
echo

# .env 파일에 토큰 적용
echo -e "${YELLOW}[4/5] .env 파일에 토큰 적용...${NC}"
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/BROWSERLESS_TOKEN=.*/BROWSERLESS_TOKEN=${TOKEN}/" .env
else
    # Linux/WSL
    sed -i "s/BROWSERLESS_TOKEN=.*/BROWSERLESS_TOKEN=${TOKEN}/" .env
fi
echo -e "${GREEN}✓ 토큰 적용 완료${NC}"
echo

# Tailscale IP 확인
echo -e "${YELLOW}[5/5] Tailscale 정보 확인...${NC}"
if command -v tailscale &> /dev/null; then
    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "")
    TAILSCALE_HOSTNAME=$(tailscale status --self --json 2>/dev/null | grep -o '"DNSName":"[^"]*"' | sed 's/"DNSName":"//;s/"//' || echo "")
    
    if [ -n "$TAILSCALE_IP" ]; then
        echo -e "${GREEN}✓ Tailscale IP: ${NC}${BLUE}${TAILSCALE_IP}${NC}"
        echo -e "${GREEN}✓ Tailscale 호스트명: ${NC}${BLUE}${TAILSCALE_HOSTNAME}${NC}"
        
        # EXTERNAL_URL 자동 설정
        if [ -n "$TAILSCALE_HOSTNAME" ]; then
            sed -i "s|EXTERNAL_URL=.*|EXTERNAL_URL=http://${TAILSCALE_HOSTNAME}:3000|" .env 2>/dev/null || true
        fi
    else
        echo -e "${YELLOW}⚠ Tailscale이 연결되어 있지 않습니다${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Tailscale이 설치되어 있지 않습니다${NC}"
    echo -e "  Windows에서 Tailscale IP를 확인하세요"
fi
echo

# 완료 메시지
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}  설정 완료!${NC}"
echo -e "${BLUE}========================================${NC}"
echo
echo -e "${YELLOW}다음 단계:${NC}"
echo -e "  1. docker-compose up -d"
echo -e "  2. http://localhost:3000/docs 에서 UI 확인"
echo
echo -e "${YELLOW}n8n/Activepieces 연결 URL:${NC}"
if [ -n "$TAILSCALE_IP" ]; then
    echo -e "  ${BLUE}ws://${TAILSCALE_IP}:3000?token=${TOKEN}${NC}"
else
    echo -e "  ${BLUE}ws://[TAILSCALE_IP]:3000?token=${TOKEN}${NC}"
fi
echo
echo -e "${YELLOW}저장된 토큰 확인:${NC}"
echo -e "  cat .env | grep BROWSERLESS_TOKEN"
echo
