param([int]$Rounds = 5, [string]$EvidenceRoot = 'docs/evidence/p0-02/stability')
$ErrorActionPreference = 'Stop'
$taskProject = Split-Path -Parent $PSScriptRoot
$taskAbsolute = Join-Path $taskProject $EvidenceRoot
if (Test-Path -LiteralPath $taskAbsolute) { throw 'EvidenceRoot already exists; preserve previous runs and choose a new directory.' }
New-Item -ItemType Directory -Force $taskAbsolute | Out-Null
$taskResults = @()
foreach ($taskRound in 1..$Rounds) {
    $taskRelative = "$EvidenceRoot/round_$taskRound"
    $taskDirectory = Join-Path $taskProject $taskRelative
    New-Item -ItemType Directory -Force $taskDirectory | Out-Null
    & "$PSScriptRoot/run.ps1" -Rendered -EvidenceDir $taskRelative *> "$taskDirectory/console.txt"
    $taskExit = $LASTEXITCODE
    $taskReport = Get-Content -Raw "$taskDirectory/rendered_results.json" | ConvertFrom-Json
    $taskClean = -not (Select-String -Path "$taskDirectory/rendered.log","$taskDirectory/import.log" -Pattern 'ERROR:|SCRIPT ERROR|FAIL:|TIMEOUT' -Quiet)
    $taskPassed = ($taskExit -eq 0 -and $taskReport.failed -eq 0 -and $taskReport.passed -ge 268 -and $taskClean)
    $taskResults += [ordered]@{ round = $taskRound; passed = $taskReport.passed; failed = $taskReport.failed; exit_code = $taskExit; clean_logs = $taskClean; accepted = $taskPassed; evidence = $taskRelative }
    $taskResults | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 "$taskAbsolute/results.json"
    Write-Output "ROUND=$taskRound passed=$($taskReport.passed) failed=$($taskReport.failed) accepted=$taskPassed"
    if (-not $taskPassed) { exit 1 }
}
exit 0
