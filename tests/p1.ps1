param(
    [switch]$Rendered,
    [switch]$FullPortrait,
    [string]$EvidenceDir = 'docs/evidence/p1-01/check-01'
)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskEvidence = [IO.Path]::GetFullPath((Join-Path $taskRoot $EvidenceDir))
if (Test-Path -LiteralPath $taskEvidence) { throw 'EvidenceDir exists; choose a new directory, preserve failed runs.' }
New-Item -ItemType Directory -Force $taskEvidence | Out-Null
. "$taskRoot/scripts/dev/use-e-drive.ps1"
$env:P1_EVIDENCE_DIR = $taskEvidence.Replace('\', '/')
$env:NSR_DATA_ROOT = "$env:P1_EVIDENCE_DIR/player-data"
$env:P1_FULL_PORTRAIT = if ($FullPortrait) { '1' } else { '0' }
$taskGodot = "$taskRoot/.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe"
if ((& $taskGodot --version) -notmatch '^4\.7\.2\.stable\.') { throw 'Expected existing Godot 4.7.2.' }
& $taskGodot --headless --path $taskRoot --editor --import --log-file "$taskEvidence/import.log"
if ($LASTEXITCODE -ne 0 -or (Select-String -LiteralPath "$taskEvidence/import.log" -Pattern 'SCRIPT ERROR|Parse Error|Compile Error')) { throw 'Import failed; inspect import.log' }
$taskArgs = @('--path', $taskRoot, '--script', 'res://tests/p1_domain_tests.gd', '--log-file', "$taskEvidence/domain.log")
& $taskGodot --headless @taskArgs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
if (Select-String -LiteralPath "$taskEvidence/domain.log" -Pattern 'SCRIPT ERROR|Parse Error|Compile Error') { throw 'Domain runtime error; counters alone are insufficient.' }
$taskArgs = @('--path', $taskRoot, '--script', 'res://tests/p1_playable_tests.gd', '--log-file', "$taskEvidence/playable.log")
if (-not $Rendered) { $taskArgs = @('--headless') + $taskArgs }
& $taskGodot @taskArgs
if (Select-String -LiteralPath "$taskEvidence/playable.log" -Pattern 'SCRIPT ERROR|Parse Error|Compile Error') { throw 'Playable runtime error; inspect log.' }
exit $LASTEXITCODE
