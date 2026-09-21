[CmdletBinding()]
param(
    [string]$RepoRoot,
    [Parameter(Mandatory)][string]$Workspace,
    [string]$GokuRoot = 'C:\GokuCodexAI',
    [string]$OverlayRoot,
    [switch]$SkillsOnly,
    [switch]$PrepareOnly
)

$ErrorActionPreference = 'Stop'
Write-Warning 'Sync-GokuaiConverterWorkspace.ps1 is deprecated; using Sync-CodexConverterWorkspace.ps1.'
$native = Join-Path $PSScriptRoot 'Sync-CodexConverterWorkspace.ps1'
if (-not (Test-Path -LiteralPath $native -PathType Leaf)) {
    throw "Native synchronization script missing: $native"
}
& $native @PSBoundParameters
exit $LASTEXITCODE
