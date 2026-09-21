[CmdletBinding()]
param(
    [Parameter(Mandatory)][int]$TerminalProcessId,
    [Parameter(Mandatory)][string]$IssueRoot,
    [int]$MaxMinutes = 8
)

$ErrorActionPreference = 'SilentlyContinue'
$resultPath = Join-Path $IssueRoot 'result.json'
$statusPath = Join-Path $IssueRoot 'worker-status.json'
$required = @('status','diagnosis','files_changed','evidence_paths','validation','remaining_risks','confidence')
$deadline = (Get-Date).AddMinutes($MaxMinutes)

function Write-Status([string]$Status, [string]$Detail) {
    $body = [ordered]@{
        status = $Status
        recoverable = $true
        message = "$Detail Codex will continue without the local worker."
        result_path = $resultPath
    } | ConvertTo-Json -Depth 4
    [IO.File]::WriteAllText($statusPath, $body, [Text.UTF8Encoding]::new($false))
}

while ((Get-Date) -lt $deadline) {
    if (Test-Path -LiteralPath $resultPath -PathType Leaf) {
        try {
            $result = Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json
            $missing = @($required | Where-Object { $null -eq $result.PSObject.Properties[$_] })
            if ($missing.Count -gt 0) { throw "missing fields: $($missing -join ', ')" }
            Write-Status 'worker_result_ready' 'The bounded local worker result is ready for Codex review.'
        }
        catch { Write-Status 'worker_result_invalid' "The bounded local worker result is malformed: $_." }
        exit
    }
    if (-not (Get-Process -Id $TerminalProcessId -ErrorAction SilentlyContinue)) {
        Write-Status 'worker_result_missing' 'The bounded local worker exited without a valid result.'
        exit
    }
    Start-Sleep -Seconds 2
}

& taskkill.exe /PID $TerminalProcessId /T /F 2>$null | Out-Null
Write-Status 'worker_timeout' "The bounded local worker exceeded $MaxMinutes minutes."
