param(
    [string]$Godot = "$PSScriptRoot/../.tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe",
    [switch]$Rendered,
    [string]$EvidenceDir = 'docs/evidence'
)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskEvidence = [IO.Path]::GetFullPath((Join-Path $taskRoot $EvidenceDir))
New-Item -ItemType Directory -Force $taskEvidence | Out-Null
$env:P0_EVIDENCE_DIR = $taskEvidence.Replace('\', '/')
$taskVersion = & $Godot --version
if ($taskVersion -notmatch '^4\.7\.2\.stable\.') { throw "需要 Godot 4.7.2 Stable，实际：$taskVersion" }
& $Godot --headless --path $taskRoot --editor --import --log-file "$taskEvidence/import.log"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
$taskArgs = @('--path', $taskRoot, '--script', 'res://tests/run_tests.gd', '--log-file')
if ($Rendered) {
    $taskArgs += "$taskEvidence/rendered.log"
} else {
    $taskArgs = @('--headless') + $taskArgs + @("$taskEvidence/headless.log")
}
& $Godot @taskArgs
exit $LASTEXITCODE
