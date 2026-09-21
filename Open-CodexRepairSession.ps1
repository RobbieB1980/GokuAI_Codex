[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ProjectPath,
    [Parameter(Mandatory)][string]$PromptFile,
    [string]$Root = 'C:\GokuCodexAI',
    [string]$CodexPath,
    [ValidateSet('primary', 'fallback')][string]$Route = 'primary',
    [switch]$PrepareOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $ProjectPath -PathType Container)) { throw "Converter project missing: $ProjectPath" }
if (-not (Test-Path -LiteralPath $PromptFile -PathType Leaf)) { throw "Repair request missing: $PromptFile" }
if (-not (Test-Path -LiteralPath $Root -PathType Container)) { throw "GokuCodexAI root missing: $Root" }
$routingPath = Join-Path $Root 'config\gokuai.json'
if (-not (Test-Path -LiteralPath $routingPath -PathType Leaf)) { throw "GokuCodexAI routing configuration missing: $routingPath" }
$routing = Get-Content -LiteralPath $routingPath -Raw | ConvertFrom-Json
if (-not $routing.codex_orchestrator) { throw "codex_orchestrator is missing from $routingPath" }
$selectedRoute = $routing.codex_orchestrator.$Route
$fallbackRoute = $routing.codex_orchestrator.fallback
if (-not $selectedRoute -or [string]::IsNullOrWhiteSpace([string]$selectedRoute.model)) { throw "codex_orchestrator.$Route is incomplete" }
if (-not $fallbackRoute -or [string]::IsNullOrWhiteSpace([string]$fallbackRoute.model)) { throw 'codex_orchestrator.fallback is incomplete' }

$workspace = (Resolve-Path -LiteralPath $ProjectPath).Path
$request = (Resolve-Path -LiteralPath $PromptFile).Path
$failed = (Resolve-Path -LiteralPath (Split-Path -Parent $request)).Path
$skill = Join-Path $failed '.agents\skills\legacy-java-converter-vnext\SKILL.md'
if (-not (Test-Path -LiteralPath $skill -PathType Leaf)) {
    throw "vNext repair skill missing from failed output: $skill"
}

if (-not $CodexPath) {
    $command = Get-Command codex -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) { $CodexPath = $command.Source }
}
if (-not $CodexPath) {
    $match = Resolve-Path 'C:\Program Files\WindowsApps\OpenAI.Codex*_x64__*\app\resources\codex.exe' -ErrorAction SilentlyContinue |
        Sort-Object Path -Descending | Select-Object -First 1
    if ($match) { $CodexPath = $match.Path }
}
if (-not $CodexPath -or -not (Test-Path -LiteralPath $CodexPath -PathType Leaf)) {
    throw 'Codex CLI could not be located. Open the Codex desktop app once, then retry.'
}

$prompt = "Open $request and execute the legacy-java-converter-vnext skill. You are the repair orchestrator running on $($selectedRoute.label) ($($selectedRoute.model), $($selectedRoute.reasoning_effort) reasoning). Use deterministic rules and the Solutions Index first, then exact-version evidence and AST repair. Preserve assets, models, items, entities, AI, and behaviour. Own integration and report build and runtime correctness as separate gates. Local KAT/Qwen workers are optional bounded helpers only. For hard issues or an orchestrator failure, preserve the evidence and rerun this handoff on $($fallbackRoute.label) ($($fallbackRoute.model), $($fallbackRoute.reasoning_effort) reasoning)."
$reasoning = 'model_reasoning_effort="' + [string]$selectedRoute.reasoning_effort + '"'
$arguments = @('-m', [string]$selectedRoute.model, '-c', $reasoning, '-C', $failed, '--add-dir', $workspace, '--add-dir', $Root, '-s', 'workspace-write', '-a', 'never', $prompt)
$prepared = [pscustomobject]@{ CodexPath = $CodexPath; WorkingDirectory = $failed; Arguments = $arguments; Request = $request; Route = $Route; Model = [string]$selectedRoute.model; FallbackModel = [string]$fallbackRoute.model; Ready = $true }
if ($PrepareOnly) { $prepared | ConvertTo-Json -Depth 4 -Compress; return }

function ConvertTo-PowerShellLiteral([string]$Value) { "'" + $Value.Replace("'", "''") + "'" }
$parts = @((ConvertTo-PowerShellLiteral $CodexPath)) + @($arguments | ForEach-Object { ConvertTo-PowerShellLiteral ([string]$_) })
$encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes('& ' + ($parts -join ' ')))
$process = Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoExit','-NoProfile','-EncodedCommand',$encoded) -WorkingDirectory $failed -PassThru
if (-not $process) { throw 'The interactive Codex repair window could not be started.' }
Write-Host "Opened Codex-orchestrated repair for $failed (PID $($process.Id))." -ForegroundColor Green
