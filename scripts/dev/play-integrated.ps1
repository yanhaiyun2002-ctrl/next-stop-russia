param([switch]$Fresh)
$ErrorActionPreference='Stop'
. "$PSScriptRoot/use-e-drive.ps1"
$taskRoot=(Resolve-Path "$PSScriptRoot/../..").Path
$taskExe=Join-Path $taskRoot 'builds/modes/playtest/NextStopRussia-PLAYTEST.exe'
if(-not (Test-Path -LiteralPath $taskExe)){throw 'Build Windows PLAYTEST first. See P1_GAMEPLAY_MAP_INTEGRATION_SUMMARY.md.'}
if(-not $env:NSR_DATA_ROOT){$env:NSR_DATA_ROOT=(Join-Path $taskRoot '.local-dev/player-data').Replace('\','/')}
$taskArgs=@('--log-file',(Join-Path $taskRoot '.local-dev/integrated-playtest.log'))
if($Fresh){$taskArgs+=@('--','--new-playtest')}
Write-Host "PLAYTEST save root: $env:NSR_DATA_ROOT"
& $taskExe @taskArgs
exit $LASTEXITCODE
