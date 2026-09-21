[CmdletBinding()]
param([string]$ProjectRoot)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = Split-Path -Parent $PSScriptRoot
}
$ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$activeRoots = @('src', 'lib', 'scripts', 'eng', 'gokuai-workspace-overlay', 'tests')
$activeFiles = @(
    'Open-GrokRepairSession.ps1',
    'Open-CodexRepairSession.ps1',
    'Convert-Forge1201-ToNeoForge262.ps1',
    'Lint-MigrationSkills.ps1'
)
$forbidden = 'grok\.exe|grok-home|GROK_HOME|grok mcp|\.grok[\\/](config\.toml|skills|agents|rules|workflows)'
$allowlistPath = Join-Path $PSScriptRoot 'fixtures\active-grok-reference-allowlist.txt'
$allowlist = @(
    if (Test-Path -LiteralPath $allowlistPath -PathType Leaf) {
        Get-Content -LiteralPath $allowlistPath |
            Where-Object { $_ -and -not $_.TrimStart().StartsWith('#') }
    }
)

function Get-RelativeAuditPath([string]$Path) {
    return $Path.Substring($ProjectRoot.Length).TrimStart('\', '/')
}

function Get-ForbiddenHits([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return }
    $relative = Get-RelativeAuditPath $Path
    if ($relative -in @('tests\Run-CodexNativeAuditTests.ps1', 'tests\fixtures\active-grok-reference-allowlist.txt')) { return }
    Select-String -LiteralPath $Path -Pattern $forbidden | ForEach-Object {
        '{0}:{1}:{2}' -f $relative, $_.LineNumber, $_.Line.Trim()
    }
}

$hits = @(
    foreach ($root in $activeRoots) {
        $path = Join-Path $ProjectRoot $root
        if (Test-Path -LiteralPath $path -PathType Container) {
            Get-ChildItem -LiteralPath $path -Recurse -File |
                Where-Object { $_.FullName -notmatch '[\\/](bin|obj)[\\/]' } |
                ForEach-Object {
                Get-ForbiddenHits $_.FullName
            }
        }
    }
    foreach ($relative in $activeFiles) {
        Get-ForbiddenHits (Join-Path $ProjectRoot $relative)
    }
)

$unexpected = @(
    $hits | Where-Object {
        $hit = $_
        -not ($allowlist | Where-Object { $hit -like $_ })
    }
)

if ($unexpected.Count -gt 0) {
    $unexpected | ForEach-Object { Write-Host "ACTIVE GROK DEPENDENCY: $_" -ForegroundColor Red }
    exit 1
}

Write-Host 'Codex native audit tests passed: no unclassified active Grok dependencies.' -ForegroundColor Green
