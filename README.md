# Browserless 데스크탑 배포

데스크탑에서 Browserless를 실행하고 n8n/Activepieces에서 원격 접속하는 구성.

## 빠른 시작

### Windows (PowerShell)

```powershell
# 1. 폴더로 이동
cd browserless

# 2. 설정 스크립트 실행
.\setup.ps1

# 3. Docker 실행
docker-compose up -d

# 4. 확인
# http://localhost:3000/docs
```

### WSL/Linux

```bash
# 1. 폴더로 이동
cd browserless

# 2. 설정 스크립트 실행
chmod +x setup.sh
./setup.sh

# 3. Docker 실행
docker-compose up -d
```

## 수동 토큰 생성

### Linux/WSL/macOS

```bash
openssl rand -base64 32 | tr -d '/+=' | cut -c1-32
```

### PowerShell

```powershell
$bytes = New-Object byte[] 24
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
([Convert]::ToBase64String($bytes) -replace '[/+=]', '').Substring(0, 32)
```

### 온라인 (개발용)

```
https://generate-random.org/api-token-generator
```

## n8n/Activepieces 연결

### 연결 URL 형식

| 방식 | URL |
|------|-----|
| WebSocket (Puppeteer) | `ws://[TAILSCALE_IP]:3000?token=YOUR_TOKEN` |
| WebSocket (Playwright Chrome) | `ws://[TAILSCALE_IP]:3000/chromium?token=YOUR_TOKEN` |
| WebSocket (Playwright Firefox) | `ws://[TAILSCALE_IP]:3000/firefox/playwright?token=YOUR_TOKEN` |
| REST API | `http://[TAILSCALE_IP]:3000?token=YOUR_TOKEN` |

### n8n 설정 예시

**Puppeteer 노드:**
```
WebSocket Endpoint: ws://100.64.0.10:3000?token=abc123
```

**HTTP Request (스크린샷 API):**
```
URL: http://100.64.0.10:3000/screenshot?token=abc123
Method: POST
Body:
{
  "url": "https://example.com",
  "options": {
    "fullPage": true
  }
}
```

### Activepieces 설정

**Browser Piece 연결:**
```
Browserless URL: ws://100.64.0.10:3000
Token: abc123def456...
```

## Tailscale IP 확인

### Windows

```powershell
tailscale ip -4
# 또는
tailscale status
```

### WSL/Linux

```bash
tailscale ip -4
```

### Tailscale Admin Console

https://login.tailscale.com/admin/machines

## 유용한 엔드포인트

| 엔드포인트 | 설명 |
|-----------|------|
| `http://localhost:3000/` | 상태 확인 |
| `http://localhost:3000/docs` | API 문서 (Swagger) |
| `http://localhost:3000/sessions` | 활성 세션 목록 |
| `http://localhost:3000/config` | 현재 설정 |
| `http://localhost:3000/metrics` | 메트릭스 |

## REST API 예시

### 스크린샷

```bash
curl -X POST "http://localhost:3000/screenshot?token=YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com"}' \
  --output screenshot.png
```

### PDF 생성

```bash
curl -X POST "http://localhost:3000/pdf?token=YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com"}' \
  --output page.pdf
```

### HTML 가져오기

```bash
curl -X POST "http://localhost:3000/content?token=YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com"}'
```

## 환경 변수

| 변수 | 기본값 | 설명 |
|------|--------|------|
| `TOKEN` | (필수) | 인증 토큰 |
| `CONCURRENT` | 10 | 동시 세션 수 |
| `QUEUED` | 10 | 대기열 크기 |
| `TIMEOUT` | 30000 | 세션 타임아웃 (ms) |
| `CORS` | false | CORS 활성화 |
| `EXTERNAL` | - | 외부 URL |
| `MAX_CPU_PERCENT` | 99 | CPU 제한 (%) |
| `MAX_MEMORY_PERCENT` | 99 | 메모리 제한 (%) |

## 문제 해결

### 연결 실패

1. 토큰 확인: `.env` 파일의 `BROWSERLESS_TOKEN`
2. 방화벽 확인: 포트 3000 허용
3. Tailscale 상태: `tailscale status`

### 메모리 부족

`docker-compose.yml`에서 메모리 제한 조정:

```yaml
deploy:
  resources:
    limits:
      memory: 8G  # 증가
```

### 로그 확인

```bash
docker-compose logs -f browserless
```

## 파일 구조

```
browserless/
├── docker-compose.yml   # Docker 설정
├── .env.example         # 환경 변수 예시
├── .env                 # 실제 환경 변수 (자동 생성)
├── setup.sh             # 설정 스크립트 (Linux/WSL)
├── setup.ps1            # 설정 스크립트 (PowerShell)
├── downloads/           # 다운로드 디렉토리
├── data/                # 데이터 디렉토리
└── README.md            # 이 파일
```

## 참고

- [Browserless 공식 문서](https://docs.browserless.io/)
- [GitHub 저장소](https://github.com/browserless/browserless)
- [Docker 이미지](https://github.com/browserless/browserless/pkgs/container/chromium)
