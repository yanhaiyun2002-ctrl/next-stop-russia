param([string]$EvidenceDir = 'docs/evidence/windows_package')
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskEvidence = [IO.Path]::GetFullPath((Join-Path $taskRoot $EvidenceDir))
if (Test-Path -LiteralPath "$taskEvidence/package_results.json") { throw 'Choose a new evidence directory; previous package results must be preserved.' }
New-Item -ItemType Directory -Force $taskEvidence | Out-Null
$taskExe = (Resolve-Path "$taskRoot/builds/windows/NextStopRussia.exe").Path
$taskBuild = Split-Path -Parent $taskExe
$env:P0_EVIDENCE_DIR = $taskEvidence.Replace('\','/')
$taskStartup = Start-Process -FilePath $taskExe -WorkingDirectory $taskBuild -ArgumentList @('--quit-after','120','--log-file',('"' + "$taskEvidence/startup.log" + '"')) -WindowStyle Hidden -PassThru
if (-not $taskStartup.WaitForExit(30000)) { Stop-Process -Id $taskStartup.Id; throw 'Standalone startup timeout' }
if ($taskStartup.ExitCode -ne 0) { exit $taskStartup.ExitCode }
$taskVerify = Start-Process -FilePath $taskExe -WorkingDirectory $taskBuild -ArgumentList @('--log-file',('"' + "$taskEvidence/package_runtime.log" + '"'),'--','--verify-package') -WindowStyle Hidden -PassThru
if (-not $taskVerify.WaitForExit(45000)) { Stop-Process -Id $taskVerify.Id; throw 'Standalone verification timeout' }
if ($taskVerify.ExitCode -ne 0) { exit $taskVerify.ExitCode }
$taskReport = Get-Content -Raw "$taskEvidence/package_results.json" | ConvertFrom-Json
if ($taskReport.editor_feature -or -not $taskReport.template_feature -or $taskReport.failed -ne 0 -or $taskReport.passed -ne 17) { throw 'Standalone checks failed' }
$taskArtifacts = @(Get-ChildItem $taskBuild -File | ForEach-Object { [ordered]@{ path='builds/windows/'+$_.Name; bytes=$_.Length; sha256=(Get-FileHash $_.FullName -Algorithm SHA256).Hash } })
$taskArtifacts | ConvertTo-Json | Set-Content -Encoding utf8 "$taskEvidence/artifacts.json"
[ordered]@{ startup_exit=$taskStartup.ExitCode; verification_exit=$taskVerify.ExitCode; passed=$taskReport.passed; failed=$taskReport.failed } | ConvertTo-Json | Set-Content -Encoding utf8 "$taskEvidence/run_status.json"
Write-Output "WINDOWS_PACKAGE passed=$($taskReport.passed) failed=$($taskReport.failed)"
exit 0
