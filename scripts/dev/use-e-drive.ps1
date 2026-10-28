# 在 E 盘项目目录的 PowerShell 终端中调用： .\scripts\dev\use-e-drive.ps1
# 仅修改当前 PowerShell 进程及从其启动的子进程的环境变量；不写入注册表/用户全局变量。
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$driveRoot = [System.IO.Path]::GetPathRoot($projectRoot)
if ($driveRoot -ieq 'C:\') {
    throw "工程位于 C 盘：$projectRoot。按项目要求请先将工程放在 E 盘或其他非 C 盘。"
}
$localRoot = Join-Path $projectRoot '.local-dev'
$dirs = @{
    Temp = (Join-Path $localRoot 'temp')
    Gradle = (Join-Path $localRoot 'gradle-cache')
    AndroidUser = (Join-Path $localRoot 'android-user')
    AndroidAvd = (Join-Path $localRoot 'android-avd')
    AndroidEmulator = (Join-Path $localRoot 'android-emulator')
    Pip = (Join-Path $localRoot 'pip-cache')
    Uv = (Join-Path $localRoot 'uv-cache')
    Npm = (Join-Path $localRoot 'npm-cache')
    PyCache = (Join-Path $localRoot 'python-pycache')
}
foreach ($p in $dirs.Values) { New-Item -Path $p -ItemType Directory -Force | Out-Null }
$env:TEMP = $dirs.Temp
$env:TMP = $dirs.Temp
$env:TMPDIR = $dirs.Temp
$env:GRADLE_USER_HOME = $dirs.Gradle
$env:ANDROID_USER_HOME = $dirs.AndroidUser
$env:ANDROID_AVD_HOME = $dirs.AndroidAvd
$env:ANDROID_EMULATOR_HOME = $dirs.AndroidEmulator
$env:PIP_CACHE_DIR = $dirs.Pip
$env:UV_CACHE_DIR = $dirs.Uv
$env:npm_config_cache = $dirs.Npm
$env:PYTHONPYCACHEPREFIX = $dirs.PyCache
Set-Location -LiteralPath $projectRoot
Write-Host "[OK] 项目/缓存优先使用：$projectRoot"
Write-Host "[OK] 进程级 TEMP = $env:TEMP"
Write-Host '[注意] 请在本终端启动 Codex / Godot / 测试；其他终端不会继承上述设置。'
Write-Host '[注意] 不能保证 Windows / Codex / 游戏 user:// 的全部写入都不经过 C 盘。'
