param([switch]$Portrait,[string]$EvidenceDir='docs/evidence/p1-ui-01/ui-01')
$ErrorActionPreference='Stop'
$taskRoot=Split-Path -Parent $PSScriptRoot
$taskEvidence=[IO.Path]::GetFullPath((Join-Path $taskRoot $EvidenceDir))
if(Test-Path -LiteralPath $taskEvidence){throw 'Keep history; choose a fresh evidence directory.'}
New-Item -ItemType Directory -Force $taskEvidence | Out-Null
. "$taskRoot/scripts/dev/use-e-drive.ps1"
$env:P1_EVIDENCE_DIR=$taskEvidence.Replace('\','/')
$env:NSR_DATA_ROOT="$env:P1_EVIDENCE_DIR/data"
$env:P1_FULL_PORTRAIT=if($Portrait){'1'}else{'0'}
$taskGodot="$taskRoot/.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe"
& $taskGodot --path $taskRoot --script res://tests/ui_visual_tests.gd --log-file "$taskEvidence/ui.log"
if($LASTEXITCODE -ne 0 -or (Select-String -LiteralPath "$taskEvidence/ui.log" -Pattern 'SCRIPT ERROR|Parse Error|Compile Error')){throw 'UI check failed; preserve evidence.'}
