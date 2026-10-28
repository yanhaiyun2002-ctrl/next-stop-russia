param(
    [string]$Godot = "$PSScriptRoot/../.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe",
    [switch]$Rendered,
    [string]$EvidenceDir = 'docs/evidence/p0-03r/ribbon'
)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskEvidence = [IO.Path]::GetFullPath((Join-Path $taskRoot $EvidenceDir))
if (Test-Path -LiteralPath $taskEvidence) { throw 'EvidenceDir exists; preserve earlier evidence and choose a new directory.' }
New-Item -ItemType Directory -Force $taskEvidence | Out-Null
$env:P0_EVIDENCE_DIR = $taskEvidence.Replace('\', '/')
$taskVersion = & $Godot --version
if ($taskVersion -notmatch '^4\.7\.2\.stable\.') { throw "Expected Godot 4.7.2 Stable, got $taskVersion" }
& $Godot --headless --path $taskRoot --editor --import --log-file "$taskEvidence/import.log"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$taskArgs = @('--path', $taskRoot, '--script', 'res://tests/ribbon_tests.gd', '--log-file', "$taskEvidence/ribbon.log")
if (-not $Rendered) { $taskArgs = @('--headless') + $taskArgs }
& $Godot @taskArgs
exit $LASTEXITCODE
