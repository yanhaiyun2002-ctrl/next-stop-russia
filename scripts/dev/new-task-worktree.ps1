param(
    [Parameter(Mandatory=$true)][ValidatePattern('^[a-z0-9][a-z0-9-]{0,39}$')][string]$Module,
    [Parameter(Mandatory=$true)][ValidatePattern('^[a-z0-9][a-z0-9-]{0,39}$')][string]$TaskId,
    [string]$Base='main'
)
$ErrorActionPreference='Stop'
$taskRepository=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$taskParent=[IO.Path]::GetFullPath('E:\俄语游戏\worktrees')
$taskName="$Module-$TaskId"
$taskTarget=[IO.Path]::GetFullPath((Join-Path $taskParent $taskName))
$taskBranch="feat/$taskName"
if(-not $taskTarget.StartsWith($taskParent+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Target outside approved Worktree root.'}
if(Test-Path -LiteralPath $taskTarget){throw 'Target exists; preserve it and choose a new task ID.'}
if((Get-PSDrive E).Free -lt 5GB){throw 'Insufficient reserved E drive space.'}
git -C $taskRepository show-ref --verify --quiet "refs/heads/$taskBranch"
if($LASTEXITCODE -eq 0){throw 'Branch exists; no branch or Worktree was overwritten.'}
$taskBaseSHA=git -C $taskRepository rev-parse --verify "$Base^{commit}"
if($LASTEXITCODE -ne 0){throw 'Base does not resolve to a local commit; verify approved base first.'}
git -C $taskRepository worktree add -b $taskBranch $taskTarget $taskBaseSHA
if($LASTEXITCODE -ne 0){throw 'Worktree creation failed; inspect existing state without cleaning.'}
Write-Host "WORKTREE=$taskTarget"
Write-Host "BRANCH=$taskBranch"
Write-Host "BASE_SHA=$taskBaseSHA"
Write-Host 'Record owner, allowedPaths and test plan before coding. No merge or push was performed.'
