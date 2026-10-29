param([switch]$Rendered,[switch]$Portrait,[string]$EvidenceDir='docs/evidence/arrival-luggage-prototype/check-01')
$ErrorActionPreference='Stop'
$taskRoot=Split-Path -Parent $PSScriptRoot
$taskEvidence=[IO.Path]::GetFullPath((Join-Path $taskRoot $EvidenceDir))
if(Test-Path -LiteralPath $taskEvidence){throw 'Keep prior evidence; choose a new directory.'}
New-Item -ItemType Directory -Force $taskEvidence | Out-Null
. "$taskRoot/scripts/dev/use-e-drive.ps1"
$env:P1_EVIDENCE_DIR=$taskEvidence.Replace('\','/')
$env:NSR_DATA_ROOT="$env:P1_EVIDENCE_DIR/bootstrap"
$env:P1_FULL_PORTRAIT=if($Portrait){'1'}else{'0'}
$taskGodot="$taskRoot/.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe"
& $taskGodot --headless --path $taskRoot --editor --import --log-file "$taskEvidence/import.log"
if($LASTEXITCODE -ne 0 -or (Select-String -LiteralPath "$taskEvidence/import.log" -Pattern 'SCRIPT ERROR|Parse Error|Compile Error')){throw 'Import failed'}
$taskArguments=@('--path',$taskRoot,'--script','res://tests/luggage_prototype_tests.gd','--log-file',"$taskEvidence/prototype.log")
if(-not $Rendered){$taskArguments=@('--headless')+$taskArguments}
$taskArguments+=@('--','--dev')
& $taskGodot @taskArguments
if($LASTEXITCODE -ne 0 -or (Select-String -LiteralPath "$taskEvidence/prototype.log" -Pattern 'SCRIPT ERROR|Parse Error|Compile Error')){throw 'Prototype engineering check failed'}
