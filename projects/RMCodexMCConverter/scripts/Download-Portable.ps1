<#
.SYNOPSIS
  Download the latest (or tagged) RB Legacy Java Converter portable ZIP from GitHub Releases.
.EXAMPLE
  .\scripts\Download-Portable.ps1
  .\scripts\Download-Portable.ps1 -Tag v2.10.12 -OutDir $env:USERPROFILE\Desktop
#>
[CmdletBinding()]
param(
    [string]$Tag = '',
    [string]$Repo = 'RobbieB1980/LegacyJavaConverter',
    [string]$OutDir = ([Environment]::GetFolderPath('Desktop')),
    [switch]$Expand
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

$api = "https://api.github.com/repos/$Repo"
$headers = @{
    Accept                 = 'application/vnd.github+json'
    'User-Agent'           = 'RB-Legacy-Java-Converter-Portable-Downloader'
    'X-GitHub-Api-Version' = '2022-11-28'
}

# Prefer git credential token when available (higher rate limit); public works without.
try {
    $fill = "protocol=https`nhost=github.com`n`n" | git credential fill 2>$null
    $token = ($fill | Where-Object { $_ -like 'password=*' }) -replace '^password=', ''
    if ($token) { $headers['Authorization'] = "Bearer $token" }
} catch { }

Write-Host "==> Resolving release" -ForegroundColor Cyan
if ($Tag) {
    $release = Invoke-RestMethod -Headers $headers -Uri "$api/releases/tags/$Tag"
} else {
    $release = Invoke-RestMethod -Headers $headers -Uri "$api/releases/latest"
}

$asset = @($release.assets) | Where-Object { $_.name -eq 'RB-Legacy-Java-Converter-Portable.zip' } | Select-Object -First 1
if (-not $asset) { throw "Release $($release.tag_name) has no RB-Legacy-Java-Converter-Portable.zip asset." }

$destZip = Join-Path $OutDir ("RB-Legacy-Java-Converter-Portable-{0}.zip" -f ($release.tag_name -replace '^v', ''))
Write-Host ("Downloading {0} ({1:N1} MB) -> {2}" -f $asset.name, ($asset.size / 1MB), $destZip) -ForegroundColor Cyan
Invoke-WebRequest -Uri $asset.browser_download_url -Headers $headers -OutFile $destZip

# Also write an unversioned copy for convenience
$latestZip = Join-Path $OutDir 'RB-Legacy-Java-Converter-Portable.zip'
Copy-Item $destZip $latestZip -Force

if ($Expand) {
    $expandDir = Join-Path $OutDir ('RB-Legacy-Java-Converter-Portable-' + ($release.tag_name -replace '^v', ''))
    if (Test-Path $expandDir) { Remove-Item $expandDir -Recurse -Force }
    Expand-Archive -LiteralPath $destZip -DestinationPath $expandDir -Force
    Write-Host "Expanded: $expandDir" -ForegroundColor Green
}

Write-Host "OK: $($release.tag_name)" -ForegroundColor Green
Write-Host "  $destZip"
Write-Host "  $latestZip"
