[CmdletBinding()]
param()

$pidPath = Join-Path $PSScriptRoot 'state\llama-server.pid'
if (-not (Test-Path -LiteralPath $pidPath)) {
    Write-Host 'No GokuAI backend PID is recorded.'
    exit 0
}
$backendPid = [int](Get-Content -LiteralPath $pidPath -Raw)
Stop-Process -Id $backendPid -Force -ErrorAction SilentlyContinue
Set-Content -LiteralPath $pidPath -Value '0' -Encoding ASCII
Write-Host "Stopped GokuAI backend PID $backendPid." -ForegroundColor Green
