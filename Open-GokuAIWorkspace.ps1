[CmdletBinding()]
param(
    [string]$Root = 'C:\GokuCodexAI',
    [ValidateSet('kat','qwen38')][string]$Profile = 'kat',
    [switch]$ValidateOnly,
    [switch]$NoFolder
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$rootPath = (Resolve-Path -LiteralPath $Root).Path
$validator = Join-Path $rootPath 'Validate-GokuAI.ps1'
$starter = Join-Path $rootPath 'Start-GokuBackend.ps1'
$converter = Join-Path $rootPath 'projects\RMCodexMCConverter'

foreach ($required in @($validator, $starter, $converter)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "GokuAI workspace dependency is missing: $required"
    }
}

& $validator
if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
    throw "GokuAI validation failed with exit code $LASTEXITCODE"
}

if ($ValidateOnly) {
    Write-Host 'GokuAI workspace launcher validation passed.' -ForegroundColor Green
    Write-Host "Root: $rootPath"
    Write-Host "Default profile: $Profile"
    Write-Host "Converter: $converter"
    exit 0
}

& $starter -Profile $Profile

if (-not $NoFolder) {
    Start-Process -FilePath 'explorer.exe' -ArgumentList @($rootPath)
}

Write-Host "GokuAI workspace is ready with the $Profile worker." -ForegroundColor Green

