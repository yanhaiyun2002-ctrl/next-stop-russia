param(
    [switch]$Dev,
    [switch]$Fresh,
    [switch]$TechnicalMap,
    [ValidateSet('', 'under_bed', 'by_window', 'by_wardrobe', 'under_desk')][string]$CatSpot = '',
    [switch]$NamePending,
    [ValidateSet('', 'q00', 'q01', 'q02', 'q03', 'home')][string]$Module = ''
)
$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/use-e-drive.ps1"
$taskRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$taskData = if ($env:NSR_DATA_ROOT) { $env:NSR_DATA_ROOT } else { Join-Path $taskRoot '.local-dev/player-data' }
$env:NSR_DATA_ROOT = $taskData.Replace('\', '/')
$taskArgs = @('--path', $taskRoot, '--log-file', (Join-Path $taskRoot '.local-dev/p1-play.log'))
$taskUserArgs = @()
if ($Dev) { $taskUserArgs += '--dev' }
if ($Fresh) {
    if ($Dev) { throw 'DEV: choose a module to create a fresh isolated preview run.' }
    $taskUserArgs += '--new-playtest'
}
if ($Module) {
    if (-not $Dev) { throw 'Module preview requires -Dev.' }
    $taskUserArgs += "--preview=$Module"
}
if ($TechnicalMap -or $CatSpot -or $NamePending) {
    if (-not $Dev) { throw 'Fixtures require explicit -Dev. PLAYTEST has no fixture controls.' }
    if ($TechnicalMap) { $taskUserArgs += '--technical-map' }
    if ($CatSpot) { $taskUserArgs += "--cat-spot=$CatSpot" }
    if ($NamePending) { $taskUserArgs += '--name-pending' }
}
if ($taskUserArgs.Count) { $taskArgs += '--'; $taskArgs += $taskUserArgs }
Write-Host "存档根目录: $env:NSR_DATA_ROOT"
& "$taskRoot/.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe" @taskArgs
exit $LASTEXITCODE
