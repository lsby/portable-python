$ErrorActionPreference = "Stop"

# 获取选项
Write-Output "获取可选择的版本..."
$url = "https://github.com/lsby/portable_python/releases/expanded_assets/python"
$response = Invoke-WebRequest -Uri $url
$htmlContent = $response.Content
$pattern = 'python-(\d+\.\d+\.\d+)-amd64.zip'
$matches = [regex]::Matches($htmlContent, $pattern)
$uniqueMatches = @{}
foreach ($match in $matches) {
    $uniqueMatches[$match.Value] = $true
}

# 用户选择
$selectedMatch = $uniqueMatches.Keys | Out-GridView -Title "Select a match" -OutputMode Single
if ([string]::IsNullOrEmpty($selectedMatch)) {
    Write-Output "用户没有选择任何版本, 脚本将退出..."
    exit
}
Write-Output "用户选择了: $selectedMatch"

# 下载
Write-Output "开始下载..."
$downloadUrl = "https://github.com/lsby/portable_python/releases/download/python/$selectedMatch"
$localFileName = Split-Path $selectedMatch -Leaf
Invoke-WebRequest -Uri $downloadUrl -OutFile $localFileName
Write-Output "下载完成..."

# 解压缩
Write-Output "开始解压..."
$extractedFolder = [System.IO.Path]::GetFileNameWithoutExtension($localFileName)
Expand-Archive -Path $localFileName -DestinationPath $extractedFolder -Force
Write-Output "解压完成..."

# 创建虚拟环境
Write-Output "开始创建虚拟环境..."
Remove-Item -Path ".\venv" -Recurse -Force -ErrorAction SilentlyContinue
$venvCommand = Join-Path $extractedFolder "python.exe"
& $venvCommand -m venv venv
Write-Output "虚拟环境创建完成..."

Write-Output "正在做最后的处理..."

# 删除压缩包
Remove-Item -Path $localFileName -Force -ErrorAction SilentlyContinue

# 删除venv/pyvenv.cfg文件
$scriptPath = $PWD.Path
$pyvenvConfigPath = Join-Path $scriptPath "venv\pyvenv.cfg"
Remove-Item -Path $pyvenvConfigPath -Force -ErrorAction SilentlyContinue

# 替换 activate 文件中的 VIRTUAL_ENV
$activateFilePath = Join-Path $scriptPath "venv\Scripts\activate"
$activateContent = Get-Content -Path $activateFilePath -Raw
$activateContent = $activateContent -replace 'VIRTUAL_ENV=".*"', 'VIRTUAL_ENV="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../"'
$activateContent | Out-File -FilePath $activateFilePath -Encoding utf8

# 替换 activate.bat 文件中的 VIRTUAL_ENV
$activateFilePath = Join-Path $scriptPath "venv\Scripts\activate.bat"
$activateContent = Get-Content -Path $activateFilePath -Raw
$activateContent = $activateContent -replace 'set VIRTUAL_ENV=.*', 'set VIRTUAL_ENV=%~dp0\..'
$activateContent | Out-File -FilePath $activateFilePath -Encoding utf8

# 提取版本号
$selectedVersion = [regex]::Match($selectedMatch, $pattern).Groups[1].Value

# 创建`进入环境.cmd`文件
$scriptContent = @"
setlocal enabledelayedexpansion

(
  echo home = %~dp0$extractedFolder
  echo include-system-site-packages = false
  echo version = $selectedVersion
  echo executable = %~dp0$extractedFolder\python.exe
  echo command = %~dp0$extractedFolder\python.exe -m venv %~dp0venv
) > %~dp0/venv/pyvenv.cfg

start .\venv\Scripts\activate.bat
"@
$scriptFilePath = Join-Path $scriptPath "进入环境.cmd"
$scriptContent | Out-File -FilePath $scriptFilePath -Encoding utf8

Write-Output "完成"
