# 1. Vim 설치 경로 확인 (기본 설치 경로인 vim91 기준)
$vimPath = "C:\Program Files\Vim\vim91"

if (Test-Path -Path $vimPath) {
    # 2. 시스템 환경 변수(Path)에 추가 (이미 등록되어 있는지 확인 후 추가)
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -notlike "*$vimPath*") {
        $newPath = "$currentPath;$vimPath"
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Host "환경 변수(Path)에 Vim 경로를 추가했습니다."
-ForegroundColor Green
    } else {
        Write-Host "이미 환경 변수에 Vim 경로가 등록되어 있습니다."
-ForegroundColor Yellow
    }

    # 3. vi -> vim 별칭(Alias)을 PowerShell 프로필에 등록
    # 프로필 파일이 없으면 생성
    if (!(Test-Path -Path $PROFILE)) {
        New-Item -ItemType File -Path $PROFILE -Force
        Write-Host "PowerShell 프로필 파일을 생성했습니다." -ForegroundColor
Cyan
    }

    # 프로필 내용 읽기
    $profileContent = Get-Content -Path $PROFILE
    $aliasCommand = "Set-Alias -Name vi -Value vim.exe"

    # 별칭이 이미 프로필에 있는지 확인 후 추가
    if ($profileContent -notcontains $aliasCommand) {
        Add-Content -Path $PROFILE -Value "`n$aliasCommand"
        Write-Host "'vi' 별칭을 PowerShell 프로필에 등록했습니다."
-ForegroundColor Green
    } else {
        Write-Host "이미 'vi' 별칭이 프로필에 등록되어 있습니다."
-ForegroundColor Yellow
    }

    Write-Host "`n모든 설정이 완료되었습니다. 새 터미널 창을 열어서 'vi' 또는
'vim'을 입력해 보세요!" -ForegroundColor Magentat
} else {
    Write-Error "Vim 설치 폴더($vimPath)를 찾을 수 없습니다. 경로를 확인해
주세요."
}
