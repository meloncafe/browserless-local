# =============================================
# Browserless 초기 설정 스크립트 (PowerShell)
# =============================================
# 실행: .\setup.ps1

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Blue
Write-Host "  Browserless 초기 설정" -ForegroundColor Blue
Write-Host "========================================" -ForegroundColor Blue
Write-Host ""

# 1. 디렉토리 생성
Write-Host "[1/5] 디렉토리 생성..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "downloads" | Out-Null
New-Item -ItemType Directory -Force -Path "data" | Out-Null
Write-Host "✓ downloads/, data/ 디렉토리 생성 완료" -ForegroundColor Green
Write-Host ""

# 2. .env 파일 생성
Write-Host "[2/5] 환경 설정 파일 확인..." -ForegroundColor Yellow
if (Test-Path ".env") {
    $response = Read-Host "⚠ .env 파일이 이미 존재합니다. 덮어쓰시겠습니까? (y/N)"
    if ($response -ne "y" -and $response -ne "Y") {
        Write-Host "기존 .env 파일 유지" -ForegroundColor Blue
    } else {
        Copy-Item ".env.example" ".env" -Force
        Write-Host "✓ .env 파일 생성 완료" -ForegroundColor Green
    }
} else {
    Copy-Item ".env.example" ".env" -Force
    Write-Host "✓ .env 파일 생성 완료" -ForegroundColor Green
}
Write-Host ""

# 3. 토큰 생성
Write-Host "[3/5] 보안 토큰 생성..." -ForegroundColor Yellow

# 안전한 랜덤 토큰 생성
$bytes = New-Object byte[] 24
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
$TOKEN = [Convert]::ToBase64String($bytes) -replace '[/+=]', '' | Select-Object -First 32
$TOKEN = $TOKEN.Substring(0, [Math]::Min(32, $TOKEN.Length))

Write-Host "✓ 생성된 토큰: " -ForegroundColor Green -NoNewline
Write-Host $TOKEN -ForegroundColor Cyan
Write-Host ""

# 4. .env 파일에 토큰 적용
Write-Host "[4/5] .env 파일에 토큰 적용..." -ForegroundColor Yellow
$content = Get-Content ".env" -Raw
$content = $content -replace "BROWSERLESS_TOKEN=.*", "BROWSERLESS_TOKEN=$TOKEN"
Set-Content ".env" $content -NoNewline
Write-Host "✓ 토큰 적용 완료" -ForegroundColor Green
Write-Host ""

# 5. Tailscale 정보 확인
Write-Host "[5/5] Tailscale 정보 확인..." -ForegroundColor Yellow
$TailscaleIP = $null
$TailscaleHostname = $null

try {
    $TailscaleIP = & tailscale ip -4 2>$null
    $TailscaleStatus = & tailscale status --self --json 2>$null | ConvertFrom-Json
    $TailscaleHostname = $TailscaleStatus.Self.DNSName
    
    if ($TailscaleIP) {
        Write-Host "✓ Tailscale IP: " -ForegroundColor Green -NoNewline
        Write-Host $TailscaleIP -ForegroundColor Cyan
        
        if ($TailscaleHostname) {
            Write-Host "✓ Tailscale 호스트명: " -ForegroundColor Green -NoNewline
            Write-Host $TailscaleHostname -ForegroundColor Cyan
            
            # EXTERNAL_URL 자동 설정
            $content = Get-Content ".env" -Raw
            $content = $content -replace "EXTERNAL_URL=.*", "EXTERNAL_URL=http://${TailscaleHostname}:3000"
            Set-Content ".env" $content -NoNewline
        }
    }
} catch {
    Write-Host "⚠ Tailscale이 설치되어 있지 않거나 연결되지 않았습니다" -ForegroundColor Yellow
}
Write-Host ""

# 완료 메시지
Write-Host "========================================" -ForegroundColor Blue
Write-Host "  설정 완료!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Blue
Write-Host ""
Write-Host "다음 단계:" -ForegroundColor Yellow
Write-Host "  1. docker-compose up -d"
Write-Host "  2. http://localhost:3000/docs 에서 UI 확인"
Write-Host ""
Write-Host "n8n/Activepieces 연결 URL:" -ForegroundColor Yellow
if ($TailscaleIP) {
    Write-Host "  ws://${TailscaleIP}:3000?token=${TOKEN}" -ForegroundColor Cyan
} else {
    Write-Host "  ws://[TAILSCALE_IP]:3000?token=${TOKEN}" -ForegroundColor Cyan
}
Write-Host ""
Write-Host "저장된 토큰 확인:" -ForegroundColor Yellow
Write-Host "  Get-Content .env | Select-String 'BROWSERLESS_TOKEN'"
Write-Host ""
Write-Host "토큰을 클립보드에 복사:" -ForegroundColor Yellow
Set-Clipboard $TOKEN
Write-Host "  ✓ 토큰이 클립보드에 복사되었습니다!" -ForegroundColor Green
