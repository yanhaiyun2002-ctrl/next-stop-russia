param([string]$EvidenceDir = 'docs/evidence/p1-01/windows-package-01', [switch]$Build)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskEvidence = [IO.Path]::GetFullPath((Join-Path $taskRoot $EvidenceDir))
if (Test-Path -LiteralPath $taskEvidence) { throw 'Choose a new evidence directory; keep previous failures.' }
New-Item -ItemType Directory -Force $taskEvidence | Out-Null
. "$taskRoot/scripts/dev/use-e-drive.ps1"
if ($Build) {
    New-Item -ItemType Directory -Force "$taskRoot/builds/p1-01" | Out-Null
    & "$taskRoot/.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe" --headless --path $taskRoot --export-release 'Windows P1 Playtest' --log-file "$taskEvidence/export.log"
    if ($LASTEXITCODE -ne 0 -or (Select-String -LiteralPath "$taskEvidence/export.log" -Pattern 'SCRIPT ERROR|Parse Error|Compile Error')) { throw 'P1 export failed' }
}
$taskExe = (Resolve-Path "$taskRoot/builds/p1-01/NextStopRussia-P1-01.exe").Path
$env:NSR_DATA_ROOT = "$taskEvidence/player-data".Replace('\','/')
$env:P1_PACKAGE_EVIDENCE = $taskEvidence.Replace('\','/')
$taskProcess = Start-Process -FilePath $taskExe -WorkingDirectory (Split-Path -Parent $taskExe) -ArgumentList @('--log-file',('"' + "$taskEvidence/runtime.log" + '"'),'--','--verify-p1-package') -WindowStyle Hidden -PassThru
if (-not $taskProcess.WaitForExit(100000)) { Stop-Process -Id $taskProcess.Id; throw 'P1 package timeout (100s)' }
if ($taskProcess.ExitCode -ne 0) { throw "P1 package exit $($taskProcess.ExitCode)" }
if (Select-String -LiteralPath "$taskEvidence/runtime.log" -Pattern 'SCRIPT ERROR|Parse Error|Compile Error') { throw 'Package runtime script error' }
$taskReport = Get-Content "$taskEvidence/package_results.json" -Raw -Encoding UTF8 | ConvertFrom-Json
if ($taskReport.failed -ne 0) { throw 'P1 standalone checks failed' }
Get-ChildItem "$taskRoot/builds/p1-01" -File | ForEach-Object { [ordered]@{path=$_.Name;bytes=$_.Length;sha256=(Get-FileHash $_.FullName -Algorithm SHA256).Hash} } | ConvertTo-Json | Set-Content "$taskEvidence/artifacts.json" -Encoding UTF8
Write-Output "P1_WINDOWS_PACKAGE passed=$($taskReport.passed) failed=$($taskReport.failed)"
