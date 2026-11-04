param([switch]$Source,[switch]$Integrated,[switch]$Landscape,[switch]$Portrait,[switch]$VerifyOnly)
$ErrorActionPreference='Stop'
if($VerifyOnly -and $Source){throw '-VerifyOnly checks an exported EXE/PCK pair; omit -Source.'}
. "$PSScriptRoot/use-e-drive.ps1"
$taskRoot=(Resolve-Path "$PSScriptRoot/../..").Path
if(-not $env:NSR_DATA_ROOT){$env:NSR_DATA_ROOT=(Join-Path $taskRoot '.local-dev/player-data').Replace('\','/')}
$taskBinary=if($Integrated){'NextStopRussia-Integrated-V04-R2.exe'}else{'NextStopRussia-School-V04-R2.exe'}
$taskExe=Join-Path $taskRoot "builds/school-v04-r2/$taskBinary"
$taskEntry=if($Integrated){'INTEGRATED'}else{'STANDALONE'}
Write-Host "[SCHOOL V0.4-R2.3-Portrait] ENTRY=$taskEntry BINARY=$taskExe DATA_ROOT=$env:NSR_DATA_ROOT"
$taskUserArgs=if($Landscape){@('--','--landscape')}else{@()}
$taskWindowArgs=if($Portrait -and $Integrated){@('--resolution','450x800')}else{@()}
if((Test-Path -LiteralPath $taskExe) -and -not $Source){
    $taskManifestPath=Join-Path $taskRoot 'builds/school-v04-r2/build_manifest.json'
    if(-not (Test-Path -LiteralPath $taskManifestPath)){throw 'R2 build manifest missing; rebuild the EXE+PCK pair or use -Source.'}
    $taskManifest=Get-Content -LiteralPath $taskManifestPath -Raw|ConvertFrom-Json
    foreach($taskExtension in @('.exe','.pck')){
        $taskPair=[IO.Path]::ChangeExtension($taskExe,$taskExtension)
        $taskName=[IO.Path]::GetFileName($taskPair)
        $taskExpected=@($taskManifest.files|Where-Object {$_.name -eq $taskName})
        if($taskExpected.Count -ne 1 -or -not (Test-Path -LiteralPath $taskPair)){throw 'R2 EXE/PCK pair is incomplete; no old build was launched.'}
        if((Get-FileHash -LiteralPath $taskPair -Algorithm SHA256).Hash -ine $taskExpected[0].sha256){throw "R2 build pair mismatch: $taskName. Rebuild; no old build was launched."}
    }
    if($VerifyOnly){Write-Host "Verified $($taskManifest.version): EXE/PCK SHA256 match."; exit 0}
    & $taskExe --log-file (Join-Path $taskRoot ".local-dev/school-r2-$taskEntry.log") @taskWindowArgs @taskUserArgs
}else{
    if($VerifyOnly){throw 'R2 exported EXE missing; verification did not launch an old build or source.'}
    $taskGodot=Join-Path $taskRoot '.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe'
    $taskScene=if($Integrated){'res://scenes/main.tscn'}else{'res://scenes/school_demo.tscn'}
    & $taskGodot --path $taskRoot $taskScene --log-file (Join-Path $taskRoot '.local-dev/school-source-playtest.log') @taskWindowArgs @taskUserArgs
}
exit $LASTEXITCODE
