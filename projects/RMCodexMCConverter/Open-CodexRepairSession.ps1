<#
.SYNOPSIS
  Prepare a failed LegacyJavaConverter output and open native Codex as the repair orchestrator.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$FailedOutput,
    [string]$GokuRoot = 'C:\GokuCodexAI',
    [string]$CodexPath,
    [ValidateSet('primary', 'fallback')][string]$Route = 'primary',
    [switch]$PrepareOnly
)

$ErrorActionPreference = 'Stop'
$failed = (Resolve-Path -LiteralPath $FailedOutput).Path
$goku = (Resolve-Path -LiteralPath $GokuRoot).Path
$routingPath = Join-Path $goku 'config\gokuai.json'
if (-not (Test-Path -LiteralPath $routingPath -PathType Leaf)) { throw "GokuCodexAI routing configuration missing: $routingPath" }
$routing = Get-Content -LiteralPath $routingPath -Raw | ConvertFrom-Json
if (-not $routing.codex_orchestrator) { throw "codex_orchestrator is missing from $routingPath" }
$selectedRoute = $routing.codex_orchestrator.$Route
$fallbackRoute = $routing.codex_orchestrator.fallback
if (-not $selectedRoute -or [string]::IsNullOrWhiteSpace([string]$selectedRoute.model)) { throw "codex_orchestrator.$Route is incomplete" }
if (-not $fallbackRoute -or [string]::IsNullOrWhiteSpace([string]$fallbackRoute.model)) { throw 'codex_orchestrator.fallback is incomplete' }

$sync = @(
    (Join-Path $PSScriptRoot 'Sync-CodexConverterWorkspace.ps1'),
    (Join-Path $PSScriptRoot 'scripts\Sync-CodexConverterWorkspace.ps1')
) | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
if (-not $sync) { throw 'Native Codex workspace synchronizer is missing from the converter bundle.' }

$bundleRoot = if (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'gokuai-workspace-overlay')) {
    $PSScriptRoot
} elseif (Test-Path -LiteralPath (Join-Path (Split-Path -Parent $PSScriptRoot) 'gokuai-workspace-overlay')) {
    Split-Path -Parent $PSScriptRoot
} else {
    $PSScriptRoot
}
$syncResult = & $sync -RepoRoot $bundleRoot -Workspace $failed -GokuRoot $goku
if (-not $syncResult.Ready) { throw 'Native Codex repair workspace synchronization did not report readiness.' }

$core = @(
    (Join-Path $PSScriptRoot 'lib\ConversionCore.ps1'),
    (Join-Path $PSScriptRoot 'tools\lib\ConversionCore.ps1')
) | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
if (-not $core) { throw 'ConversionCore.ps1 is missing from the converter bundle.' }
. $core
$request = Write-CodexRepairRequest -FailedOutput $failed -DestinationJavaMajor 25 -TargetMinecraft '26.2'

$codex = $null
if ($CodexPath) {
    if (-not (Test-Path -LiteralPath $CodexPath -PathType Leaf)) { throw "Specified Codex CLI does not exist: $CodexPath" }
    $codex = (Resolve-Path -LiteralPath $CodexPath).Path
} else {
    $command = Get-Command codex -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) { $codex = $command.Source }
    if (-not $codex) {
        $codex = Get-ChildItem -Path @(
            'C:\Program Files\WindowsApps\OpenAI.CodexBeta_*\app\resources\codex.exe',
            'C:\Program Files\WindowsApps\OpenAI.Codex_*\app\resources\codex.exe'
        ) -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1 -ExpandProperty FullName
    }
}
if (-not $codex) {
    throw 'Codex CLI could not be located. Open the Codex desktop app once, then retry Repair with GokuCodexAI.'
}

$openingPrompt = "Use the legacy-java-converter-vnext skill. Read '$request' and AGENTS.md, then own the deterministic-first repair and separate build/runtime validation for this failed output. You are the repair orchestrator running on $($selectedRoute.label) ($($selectedRoute.model), $($selectedRoute.reasoning_effort) reasoning). For hard issues or an orchestrator failure, preserve the evidence and rerun this handoff on $($fallbackRoute.label) ($($fallbackRoute.model), $($fallbackRoute.reasoning_effort) reasoning)."
$reasoning = 'model_reasoning_effort="' + [string]$selectedRoute.reasoning_effort + '"'
$codexArguments = @(
    '-m', [string]$selectedRoute.model,
    '-c', $reasoning,
    '-C', $failed,
    '--add-dir', $goku,
    '-s', 'workspace-write',
    '-a', 'never',
    $openingPrompt
)

$result = [pscustomobject]@{
    Ready = $true
    FailedOutput = $failed
    RequestFile = $request
    CodexPath = $codex
    Route = $Route
    Model = [string]$selectedRoute.model
    FallbackModel = [string]$fallbackRoute.model
    Arguments = $codexArguments
}
if ($PrepareOnly) {
    $result | ConvertTo-Json -Depth 4 -Compress
    exit 0
}

function ConvertTo-PowerShellLiteral([string]$Value) {
    return "'" + $Value.Replace("'", "''") + "'"
}
$commandParts = @((ConvertTo-PowerShellLiteral $codex))
$commandParts += @($codexArguments | ForEach-Object { ConvertTo-PowerShellLiteral ([string]$_) })
$interactiveCommand = '& ' + ($commandParts -join ' ')
$encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($interactiveCommand))
$process = Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoExit', '-NoProfile', '-EncodedCommand', $encodedCommand) -WorkingDirectory $failed -PassThru
if (-not $process) { throw 'The interactive Codex repair window could not be started.' }
Write-Host "Opened GokuCodexAI repair session for $failed (PID $($process.Id))." -ForegroundColor Green
