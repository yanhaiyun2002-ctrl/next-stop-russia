param([switch]$Rendered,[string]$EvidenceDir='docs/evidence/school-v04/check-01')
$ErrorActionPreference='Stop'
$taskRoot=Split-Path -Parent $PSScriptRoot
$taskEvidence=[IO.Path]::GetFullPath((Join-Path $taskRoot $EvidenceDir))
if(Test-Path -LiteralPath $taskEvidence){throw 'Choose a new EvidenceDir to preserve earlier results.'}
New-Item -ItemType Directory -Force $taskEvidence | Out-Null
. "$taskRoot/scripts/dev/use-e-drive.ps1"
$env:SCHOOL_EVIDENCE_DIR=$taskEvidence.Replace('\','/')
$env:NSR_DATA_ROOT="$env:SCHOOL_EVIDENCE_DIR/player-data"
$taskGodot="$taskRoot/.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe"
foreach($taskScript in @('school_domain_tests.gd','school_ui_tests.gd','school_integration_tests.gd')){
    $taskLog=Join-Path $taskEvidence "$taskScript.log"
    $taskArgs=@('--path',$taskRoot,'--script',"res://tests/$taskScript",'--log-file',$taskLog)
    if(-not $Rendered -or $taskScript -ne 'school_ui_tests.gd'){$taskArgs=@('--headless')+$taskArgs}
    & $taskGodot @taskArgs
    if($LASTEXITCODE -ne 0 -or (Select-String -LiteralPath $taskLog -Pattern 'SCRIPT ERROR|Parse Error|Compile Error')){throw "Failed: $taskScript; inspect $taskLog"}
}
