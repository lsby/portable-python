param (
    [string]$selectedMatch = $env:ONE_CLICK_RUN_PORTABLE_PYTHON_SELECTEDMATCH
)

$ErrorActionPreference = "Stop"

# 如果没有传入版本，则获取可选版本并弹出选择界面
if (-not $selectedMatch) {
    Write-Output "获取可选择的版本..."
    $url = "https://github.com/one-click-run/portable-python/releases/expanded_assets/python"
    $response = Invoke-WebRequest -Uri $url
    $htmlContent = $response.Content
    $pattern = 'python-(\d+\.\d+\.\d+)-amd64.zip'
    $matches = [regex]::Matches($htmlContent, $pattern)
    $uniqueMatches = @{}
    foreach ($match in $matches) {
        $uniqueMatches[$match.Value] = $true
    }

    # 弹出选择界面
    $selectedMatch = $uniqueMatches.Keys | Out-GridView -Title "Select a match" -OutputMode Single

    # 如果用户没有选择任何版本，退出脚本
    if ([string]::IsNullOrEmpty($selectedMatch)) {
        Write-Output "用户没有选择任何版本, 脚本将退出..."
        exit
    }
}

Write-Output "用户选择了: $selectedMatch"

# 下载
Write-Output "开始下载..."
$downloadUrl = "https://github.com/one-click-run/portable-python/releases/download/python/$selectedMatch"
$localFileName = "OCR-portable-python.zip"
Invoke-WebRequest -Uri $downloadUrl -OutFile $localFileName
Write-Output "下载完成..."

# 解压缩
Write-Output "开始解压..."
$extractedFolder = [System.IO.Path]::GetFileNameWithoutExtension($localFileName)
Expand-Archive -Path $localFileName -DestinationPath $extractedFolder -Force
Write-Output "解压完成..."

# 创建虚拟环境
Write-Output "开始创建虚拟环境..."
Remove-Item -Path ".\OCR-portable-python-venv" -Recurse -Force -ErrorAction SilentlyContinue
$venvCommand = Join-Path $extractedFolder "python.exe"
& $venvCommand -m venv OCR-portable-python-venv
Write-Output "虚拟环境创建完成..."

Write-Output "正在做最后的处理..."

# 删除压缩包
Remove-Item -Path $localFileName -Force -ErrorAction SilentlyContinue

# 替换 activate 文件
$scriptPath = $PWD.Path
$activateFilePath = Join-Path $scriptPath "OCR-portable-python-venv\Scripts\activate"
$activateContent = Get-Content -Path $activateFilePath -Raw
$activateContent = $activateContent -replace [regex]::Escape("$scriptPath\venv"), '$( cd $( dirname ${BASH_SOURCE[0]} ) && pwd )/../'
[System.IO.File]::WriteAllLines($activateFilePath, $activateContent)

# 替换 activate.bat 文件
$activateFilePath = Join-Path $scriptPath "OCR-portable-python-venv\Scripts\activate.bat"
$activateContent = Get-Content -Path $activateFilePath -Raw
$activateContent = $activateContent -replace [regex]::Escape("$scriptPath\venv"), '%~dp0\..'
[System.IO.File]::WriteAllLines($activateFilePath, $activateContent)

# 创建修复文件
$scriptContent = @"
setlocal enabledelayedexpansion

set "charset=abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
set "length=8"
set "randStr="
for /l %%i in (1,1,%length%) do (
    set /a "index=!random! %% 62"
    for %%j in (!index!) do set "randStr=!randStr!!charset:~%%j,1!"
)

set "venvTemp=OCR-portable-python-venv-%randStr%"
rename OCR-portable-python-venv !venvTemp!

set venvCommand=.\OCR-portable-python\python.exe
%venvCommand% -m venv OCR-portable-python-venv

for /d %%d in (.\"!venvTemp!\"\*) do (
    if /i not "%%~nxd"=="Scripts" (
        if exist .\OCR-portable-python-venv\"%%~nxd" rmdir /s /q .\OCR-portable-python-venv\"%%~nxd"
        move "%%d" .\OCR-portable-python-venv
    )
)

rmdir /s /q !venvTemp!

endlocal

start .\OCR-portable-python-venv\Scripts\activate.bat
"@
$scriptFilePath = Join-Path $scriptPath "OCR-portable-python-fix.cmd"
[System.IO.File]::WriteAllLines($scriptFilePath, $scriptContent)

# 创建进入环境文件
$scriptContent = @"
@echo off
start .\OCR-portable-python-venv\Scripts\activate.bat
"@
$scriptFilePath = Join-Path $scriptPath "OCR-portable-python.cmd"
[System.IO.File]::WriteAllLines($scriptFilePath, $scriptContent)

Write-Output "完成"
