param([string]$EvidenceDir='docs/evidence/p1-01r-dev-modes/windows-01',[switch]$SkipBuild,[switch]$LuggagePrototype)
$ErrorActionPreference='Stop'
$taskRoot=Split-Path -Parent $PSScriptRoot
$taskEvidence=[IO.Path]::GetFullPath((Join-Path $taskRoot $EvidenceDir))
if(Test-Path -LiteralPath $taskEvidence){throw 'Evidence exists; preserve failed runs.'}
New-Item -ItemType Directory -Force $taskEvidence | Out-Null
. "$taskRoot/scripts/dev/use-e-drive.ps1"
$taskGodot="$taskRoot/.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe"
$taskScratch=Join-Path $taskEvidence 'pack-audit-project'
New-Item -ItemType Directory -Force $taskScratch | Out-Null
'config_version=5' | Set-Content -LiteralPath "$taskScratch/project.godot" -Encoding utf8
Copy-Item -LiteralPath "$taskRoot/tests/pck_mode_audit.gd" -Destination "$taskScratch/audit.gd"
$taskResults=@()
foreach($taskMode in @('DEV','PLAYTEST','RELEASE')){
    $taskLower=$taskMode.ToLowerInvariant()
    $taskBuild="$taskRoot/builds/modes/$taskLower"
    New-Item -ItemType Directory -Force $taskBuild | Out-Null
    if(-not $SkipBuild){
        & $taskGodot --headless --path $taskRoot --export-release "Windows $taskMode" --log-file "$taskEvidence/export-$taskLower.log"
        if($LASTEXITCODE -ne 0 -or (Select-String -LiteralPath "$taskEvidence/export-$taskLower.log" -Pattern 'SCRIPT ERROR|Parse Error|Compile Error')){throw "$taskMode export failed"}
    }
    $env:NSR_AUDIT_MODE=$taskMode
    $env:NSR_AUDIT_PACK="$taskBuild/NextStopRussia-$taskMode.pck"
    $env:NSR_AUDIT_OUT="$taskEvidence/pack-$taskLower.json"
    & $taskGodot --headless --path $taskScratch --script res://audit.gd --log-file "$taskEvidence/pack-$taskLower.log"
    if($LASTEXITCODE -ne 0){throw "$taskMode pack capability audit failed"}
    $taskData="$taskEvidence/data-$taskLower"
    $env:NSR_DATA_ROOT=$taskData.Replace('\','/')
    & $taskGodot --headless --path $taskRoot --script res://tests/mode_pack_seed.gd --log-file "$taskEvidence/seed-$taskLower.log"
    if($LASTEXITCODE -ne 0){throw 'Seed failed'}
    $taskBefore=@{}
    foreach($taskChannel in @('DEV','PLAYTEST','RELEASE')){$taskBefore[$taskChannel]=(Get-FileHash "$taskData/$taskChannel/save.json").Hash}
    $taskRuntime="$taskEvidence/runtime-$taskLower.log"
    $taskArgs=@('--log-file',('"'+$taskRuntime+'"'),'--quit-after','180','--','--dev','--mode=DEV','--preview=q02','--name-pending','--technical-map','--cat-spot=under_bed')
    if($taskMode -eq 'RELEASE'){$taskArgs+=@('--new-playtest','--verify-p1-package')}
    if($LuggagePrototype){$taskArgs+='--luggage-prototype'}
    # DEV gets one unambiguous module request; negative builds get every legacy attack flag.
    if($taskMode -eq 'DEV'){$taskArgs=@('--log-file',('"'+$taskRuntime+'"'),'--quit-after','180','--','--preview=q02')}
    if($taskMode -eq 'DEV' -and $LuggagePrototype){$taskArgs=@('--log-file',('"'+$taskRuntime+'"'),'--quit-after','180','--','--luggage-prototype')}
    $taskProcess=Start-Process -FilePath "$taskBuild/NextStopRussia-$taskMode.exe" -WorkingDirectory $taskBuild -ArgumentList $taskArgs -WindowStyle Hidden -RedirectStandardOutput "$taskEvidence/stdout-$taskLower.log" -RedirectStandardError "$taskEvidence/stderr-$taskLower.log" -PassThru
    # Retain the native handle before exit (Windows PowerShell otherwise may
    # lose ExitCode for a short-lived process returned by Start-Process).
    $null=$taskProcess.Handle
    if(-not $taskProcess.WaitForExit(20000)){Stop-Process -Id $taskProcess.Id; throw "$taskMode graceful runtime timeout"}
    $taskProcess.WaitForExit()
    $taskProcess.Refresh()
    if($null -eq $taskProcess.ExitCode){throw "$taskMode exit code unavailable; do not claim runtime PASS"}
    if($taskProcess.ExitCode -ne 0){throw "$taskMode standalone exit $($taskProcess.ExitCode)"}
    $taskLog=Get-Content -LiteralPath $taskRuntime -Raw
    if($taskLog -notmatch "NSR_MODE=$taskMode " -or $taskLog -match 'SCRIPT ERROR|Parse Error|Compile Error'){throw "$taskMode actual runtime failed"}
    foreach($taskChannel in @('DEV','PLAYTEST','RELEASE')){
        if((Get-FileHash "$taskData/$taskChannel/save.json").Hash -ne $taskBefore[$taskChannel]){throw "$taskMode changed regular $taskChannel save"}
    }
    $taskPreviewCount=@(Get-ChildItem -LiteralPath "$taskData/DEV" -Recurse -Filter save.json).Count-1
    if(($taskMode -eq 'DEV' -and -not $LuggagePrototype -and $taskPreviewCount -lt 1) -or (($taskMode -ne 'DEV' -or $LuggagePrototype) -and $taskPreviewCount -ne 0)){throw "$taskMode preview namespace check failed"}
    if($taskMode -ne 'DEV' -and (Test-Path -LiteralPath "$taskData/PLAYTEST/profiles")){throw 'Negative debug flags created a test profile'}
    $taskResults+=@{mode=$taskMode;runtime='PASS';regularSaveHashesUnchanged=$true;previewSaveCount=$taskPreviewCount;arguments=$taskArgs;packAudit="pack-$taskLower.json"}
    Get-ChildItem -LiteralPath $taskBuild -File | ForEach-Object {[ordered]@{path=$_.Name;bytes=$_.Length;sha256=(Get-FileHash $_.FullName -Algorithm SHA256).Hash}} | ConvertTo-Json | Set-Content -LiteralPath "$taskEvidence/artifacts-$taskLower.json" -Encoding utf8
}
$taskResults | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath "$taskEvidence/windows_modes_results.json" -Encoding utf8
Write-Output 'WINDOWS_MODES three builds PASS; release/playtest debug escalation rejected; all regular saves unchanged.'
