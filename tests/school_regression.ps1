param([string]$EvidenceDir='docs/evidence/school-v04/regression-01',[string]$FromSuite='p1_domain_tests')
$ErrorActionPreference='Stop'
$taskRoot=Split-Path -Parent $PSScriptRoot
$taskEvidence=[IO.Path]::GetFullPath((Join-Path $taskRoot $EvidenceDir))
if(Test-Path -LiteralPath $taskEvidence){throw 'Choose a new evidence directory.'}
New-Item -ItemType Directory -Force $taskEvidence | Out-Null
. "$taskRoot/scripts/dev/use-e-drive.ps1"
$taskGodot="$taskRoot/.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe"
$taskSuites=@('p1_domain_tests','p1_playable_tests','p1_modes_tests','luggage_prototype_tests','cat_hunt_tests','run_tests')
if($FromSuite -notin $taskSuites){throw 'Unknown starting suite.'}
$taskSuites=$taskSuites[$taskSuites.IndexOf($FromSuite)..($taskSuites.Count-1)]
foreach($taskSuite in $taskSuites){
    $taskCase=Join-Path $taskEvidence $taskSuite
    New-Item -ItemType Directory -Force $taskCase | Out-Null
    $env:P1_EVIDENCE_DIR=$taskCase.Replace('\','/')
    $env:P0_EVIDENCE_DIR=$env:P1_EVIDENCE_DIR
    $env:NSR_DATA_ROOT="$env:P1_EVIDENCE_DIR/player-data"
    $env:P1_FULL_PORTRAIT='0'
    $taskLog=Join-Path $taskCase 'test.log'
    $taskArgs=@('--headless','--path',$taskRoot,'--script',"res://tests/$taskSuite.gd",'--log-file',$taskLog)
    if($taskSuite -eq 'luggage_prototype_tests'){$taskArgs+=@('--','--dev')}
    & $taskGodot @taskArgs
    if($LASTEXITCODE -ne 0 -or (Select-String -LiteralPath $taskLog -Pattern 'SCRIPT ERROR|Parse Error|Compile Error')){throw "Failed $taskSuite; inspect $taskLog"}
}
