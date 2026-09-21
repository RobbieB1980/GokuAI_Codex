<#
.SYNOPSIS
  Deprecated compatibility entry that forwards failed repairs to native Codex.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$FailedOutput,
    [string]$GokuRoot = 'C:\GokuCodexAI',
    [string]$Workspace,
    [string]$CodexPath,
    [switch]$PrepareOnly
)

$ErrorActionPreference = 'Stop'
Write-Warning 'This deprecated compatibility launcher now uses the native Codex repair launcher.'
$native = Join-Path $PSScriptRoot 'Open-CodexRepairSession.ps1'
if (-not (Test-Path -LiteralPath $native -PathType Leaf)) {
    throw "Native repair launcher missing: $native"
}
$request = Join-Path $FailedOutput 'CODEX_REPAIR_REQUEST.md'
if (-not (Test-Path -LiteralPath $request -PathType Leaf)) { throw "Native repair request missing: $request" }
$arguments = @{
    ProjectPath = $(if ($Workspace) { $Workspace } else { Join-Path $GokuRoot 'projects\RMCodexMCConverter' })
    PromptFile = $request
    Root = $GokuRoot
    PrepareOnly = $PrepareOnly
}
if ($CodexPath) { $arguments.CodexPath = $CodexPath }
& $native @arguments
exit $LASTEXITCODE
