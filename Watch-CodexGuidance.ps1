<# Deprecated compatibility watcher. Codex now owns the repair directly. #>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][int]$TerminalProcessId,
    [Parameter(Mandatory)][string]$ProjectRoot,
    [int]$MaxMinutes = 30
)

$ErrorActionPreference = 'SilentlyContinue'
$deadline = (Get-Date).AddMinutes($MaxMinutes)
while ((Get-Date) -lt $deadline) {
    if (-not (Get-Process -Id $TerminalProcessId -ErrorAction SilentlyContinue)) { exit }
    Start-Sleep -Seconds 2
}
Write-Warning 'Codex repair session exceeded the observation window; no automatic worker handoff was started.'
