[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Write-Warning 'Run-GokuHandoffTests.ps1 is deprecated; running Run-CodexHandoffTests.ps1.'
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'Run-CodexHandoffTests.ps1')
exit $LASTEXITCODE
