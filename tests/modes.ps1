param([switch]$Dev,[switch]$Rendered,[switch]$Portrait,[string]$EvidenceDir='docs/evidence/p1-01r-dev-modes/check-01')
$ErrorActionPreference='Stop'
$taskRoot=Split-Path -Parent $PSScriptRoot
$taskEvidence=[IO.Path]::GetFullPath((Join-Path $taskRoot $EvidenceDir))
if(Test-Path -LiteralPath $taskEvidence){throw 'Evidence exists; preserve previous runs.'}
New-Item -ItemType Directory -Force $taskEvidence | Out-Null
. "$taskRoot/scripts/dev/use-e-drive.ps1"
$env:P1_EVIDENCE_DIR=$taskEvidence.Replace('\','/')
$env:NSR_DATA_ROOT="$env:P1_EVIDENCE_DIR/player-data"
$env:P1_FULL_PORTRAIT=if($Portrait){'1'}else{'0'}
$taskGodot="$taskRoot/.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe"
& $taskGodot --headless --path $taskRoot --editor --import --log-file "$taskEvidence/import.log"
if($LASTEXITCODE -ne 0 -or (Select-String -LiteralPath "$taskEvidence/import.log" -Pattern 'SCRIPT ERROR|Parse Error|Compile Error')){throw 'Import failed'}
$taskArguments=@('--path',$taskRoot,'--script','res://tests/p1_modes_tests.gd','--log-file',"$taskEvidence/modes.log")
if(-not $Rendered){$taskArguments=@('--headless')+$taskArguments}
if($Dev){$taskArguments+=@('--','--dev')}
& $taskGodot @taskArguments
if($LASTEXITCODE -ne 0 -or (Select-String -LiteralPath "$taskEvidence/modes.log" -Pattern 'SCRIPT ERROR|Parse Error|Compile Error')){throw 'Modes test failed; preserve logs.'}
