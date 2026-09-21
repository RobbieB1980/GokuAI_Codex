[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ProjectPath,
    [Parameter(Mandatory)][string]$PromptFile,
    [string]$Root = 'C:\GokuCodexAI',
    [int]$Port = 8888,
    [int]$MaxMinutes = 8,
    [switch]$PrepareOnly,
    [ValidateSet('none','missing','timeout','malformed')][string]$SimulateOutcome = 'none'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $ProjectPath -PathType Container)) { throw "Project missing: $ProjectPath" }
if (-not (Test-Path -LiteralPath $PromptFile -PathType Leaf)) { throw "Repair request missing: $PromptFile" }

$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$requestFile = (Resolve-Path -LiteralPath $PromptFile).Path
$issueId = 'local-' + [guid]::NewGuid().ToString('N')
$issueRoot = Join-Path $project ".gokuai\issues\$issueId"
New-Item -ItemType Directory -Path $issueRoot -Force | Out-Null
$resultPath = Join-Path $issueRoot 'result.json'
$packetPath = Join-Path $issueRoot 'request.json'
$packet = [ordered]@{
    issue_id = $issueId
    problem = "Provide bounded evidence-backed assistance for $requestFile"
    acceptance_criteria = @('Return the required result schema', 'Do not apply edits directly')
    evidence_paths = @($requestFile)
    failure_excerpt = ''
    validation_commands = @()
    result_path = $resultPath
}
[IO.File]::WriteAllText($packetPath, ($packet | ConvertTo-Json -Depth 5), [Text.UTF8Encoding]::new($false))

function Write-RecoverableStatus([string]$WorkerStatus, [string]$Detail) {
    $message = "$Detail Codex will continue without the local worker."
    $statusPath = Join-Path $issueRoot 'worker-status.json'
    $statusObject = [pscustomobject]@{ issue_id=$issueId; status=$WorkerStatus; recoverable=$true; message=$message; request_path=$packetPath; result_path=$resultPath }
    [IO.File]::WriteAllText($statusPath, ($statusObject | ConvertTo-Json -Depth 4), [Text.UTF8Encoding]::new($false))
    return ($statusObject | ConvertTo-Json -Compress)
}

if ($SimulateOutcome -eq 'missing') { Write-RecoverableStatus 'worker_unavailable' 'The local worker executable is missing.'; return }
if ($SimulateOutcome -eq 'timeout') { Write-RecoverableStatus 'worker_timeout' 'The bounded local worker timed out.'; return }
if ($SimulateOutcome -eq 'malformed') {
    [IO.File]::WriteAllText($resultPath, '{"status":"maybe"}', [Text.UTF8Encoding]::new($false))
    Write-RecoverableStatus 'worker_result_invalid' 'The local worker returned malformed result.json.'
    return
}

$runtime = Join-Path $Root 'runtime\llama.cpp\llama-server.exe'
if (-not (Test-Path -LiteralPath $runtime -PathType Leaf)) {
    Write-RecoverableStatus 'worker_unavailable' "The local worker executable is missing: $runtime."
    return
}
if ($PrepareOnly) {
    [pscustomobject]@{ issue_id=$issueId; status='prepared'; recoverable=$true; message='Optional local worker request prepared; Codex retains control.'; request_path=$packetPath; result_path=$resultPath } | ConvertTo-Json -Compress
    return
}

$backend = Join-Path $Root 'Start-GokuBackend.ps1'
try { $health = Invoke-RestMethod -Uri "http://127.0.0.1:$Port/health" -TimeoutSec 3 } catch { $health = $null }
if (-not $health -or $health.status -ne 'ok') {
    if (-not (Test-Path -LiteralPath $backend -PathType Leaf)) {
        Write-RecoverableStatus 'worker_unavailable' "The local worker starter is missing: $backend."
        return
    }
    & $backend -Port $Port
}

$codexCommand = Get-Command codex -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $codexCommand) {
    Write-RecoverableStatus 'worker_unavailable' 'The Codex local-worker host is unavailable.'
    return
}

$prompt = "OPTIONAL BOUNDED WORKER. Read only $packetPath and its evidence paths. Do not edit source files. Write the required JSON result to $resultPath with status, diagnosis, files_changed, evidence_paths, validation, remaining_risks, and confidence, then stop."
$args = @('-C',$project,'-s','read-only','-a','never','-m','goku-local','-c','model_provider="goku"','-c',"model_providers.goku.base_url=`"http://127.0.0.1:$Port/v1`"",$prompt)
$process = Start-Process -FilePath $codexCommand.Source -ArgumentList $args -WorkingDirectory $project -PassThru
if (-not $process) { Write-RecoverableStatus 'worker_unavailable' 'The optional local worker did not start.'; return }

$watcher = Join-Path $PSScriptRoot 'Watch-KATRepairSession.ps1'
Start-Process powershell.exe -ArgumentList @('-NoProfile','-WindowStyle','Hidden','-File',$watcher,'-TerminalProcessId',$process.Id,'-IssueRoot',$issueRoot,'-MaxMinutes',$MaxMinutes) -WindowStyle Hidden | Out-Null
[pscustomobject]@{ issue_id=$issueId; status='running'; recoverable=$true; message='Optional local worker started; Codex retains orchestration authority.'; request_path=$packetPath; result_path=$resultPath } | ConvertTo-Json -Compress
