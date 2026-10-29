param([switch]$Rendered,[switch]$Portrait,[string]$EvidenceDir='docs/evidence/gameplay-map-integration/check-01')
$ErrorActionPreference='Stop'
$taskRoot=Split-Path -Parent $PSScriptRoot
$taskEvidence=[IO.Path]::GetFullPath((Join-Path $taskRoot $EvidenceDir))
if(Test-Path -LiteralPath $taskEvidence){throw 'Preserve evidence; use a fresh directory.'}
New-Item -ItemType Directory -Force $taskEvidence | Out-Null
. "$taskRoot/scripts/dev/use-e-drive.ps1"
$env:P1_EVIDENCE_DIR=$taskEvidence.Replace('\','/')
$env:NSR_DATA_ROOT="$env:P1_EVIDENCE_DIR/bootstrap"
$env:P1_FULL_PORTRAIT=if($Portrait){'1'}else{'0'}
$taskGodot="$taskRoot/.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe"
$taskArguments=@('--path',$taskRoot,'--script','res://tests/gameplay_map_integration_tests.gd','--log-file',"$taskEvidence/integration.log")
if(-not $Rendered){$taskArguments=@('--headless')+$taskArguments}
& $taskGodot @taskArguments
if($LASTEXITCODE -ne 0 -or (Select-String -LiteralPath "$taskEvidence/integration.log" -Pattern 'SCRIPT ERROR|Parse Error|Compile Error')){throw 'Integration check failed; preserve log.'}
