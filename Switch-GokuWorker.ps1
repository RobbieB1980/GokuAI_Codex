[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('default','fast','repair','escalation','review','heavy')][string]$Worker,
    [int]$Port = 8888
)

$profile = if ($Worker -in @('escalation','review','heavy')) { 'qwen38' } else { 'kat' }
Write-Host "Worker '$Worker' -> profile '$profile'" -ForegroundColor Green
& (Join-Path $PSScriptRoot 'Start-GokuBackend.ps1') -Profile $profile -Port $Port -ForceRestart
