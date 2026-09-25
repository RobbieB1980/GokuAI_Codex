[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'
$failures = 0
function Check([string]$Label, [bool]$Condition, [string]$Detail = '') {
    if ($Condition) { Write-Host "[OK] $Label" -ForegroundColor Green }
    else { Write-Host "[FAIL] $Label $Detail" -ForegroundColor Red; $script:failures++ }
}

$configPath = Join-Path $PSScriptRoot 'config\gokuai.json'
$codexConfigPath = Join-Path $PSScriptRoot '.codex\config.toml'
Check 'configuration exists' (Test-Path -LiteralPath $configPath -PathType Leaf) $configPath
Check 'Codex MCP configuration exists' (Test-Path -LiteralPath $codexConfigPath -PathType Leaf) $codexConfigPath
try { $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json } catch { Write-Host "[FAIL] invalid configuration: $_" -ForegroundColor Red; exit 1 }

Check 'canonical GokuCodexAI root' ($config.root -eq 'C:\GokuCodexAI') ([string]$config.root)
Check 'local worker runtime' (Test-Path -LiteralPath $config.runtime -PathType Leaf) ([string]$config.runtime)
Check 'knowledge root' (Test-Path -LiteralPath $config.knowledge.root -PathType Container) ([string]$config.knowledge.root)
Check 'hardened fixes' (Test-Path -LiteralPath $config.knowledge.hardened_fixes -PathType Container) ([string]$config.knowledge.hardened_fixes)
Check 'active index pointer' (Test-Path -LiteralPath $config.knowledge.active_index_pointer -PathType Leaf) ([string]$config.knowledge.active_index_pointer)
Check 'KAT worker model' (Test-Path -LiteralPath $config.workers.default.model -PathType Leaf) ([string]$config.workers.default.model)
$reviewWorker = if ($config.workers.PSObject.Properties.Name -contains 'review') { $config.workers.review } else { $config.workers.escalation }
Check 'Qwen worker model' (Test-Path -LiteralPath $reviewWorker.model -PathType Leaf) ([string]$reviewWorker.model)
Check 'Luna High primary orchestrator' ($config.codex_orchestrator.primary.model -eq 'gpt-5.6-luna-high') ([string]$config.codex_orchestrator.primary.model)
Check 'Sol Medium fallback orchestrator' ($config.codex_orchestrator.fallback.model -eq 'gpt-5.6-sol-medium') ([string]$config.codex_orchestrator.fallback.model)
Check 'Luna High reasoning' ($config.codex_orchestrator.primary.reasoning_effort -eq 'high') ([string]$config.codex_orchestrator.primary.reasoning_effort)
Check 'Sol Medium reasoning' ($config.codex_orchestrator.fallback.reasoning_effort -eq 'medium') ([string]$config.codex_orchestrator.fallback.reasoning_effort)

$codex = Get-Command codex -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $codex) {
    $codex = Resolve-Path 'C:\Program Files\WindowsApps\OpenAI.Codex*_x64__*\app\resources\codex.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
}
Check 'Codex CLI discovery' ($null -ne $codex)

$codexConfig = if (Test-Path $codexConfigPath) { Get-Content -LiteralPath $codexConfigPath -Raw } else { '' }
Check 'MCP command uses canonical root' ($codexConfig -match [regex]::Escape('C:\GokuCodexAI\runtime\python-mcp-v2\Scripts\python.exe'))
Check 'MCP database uses canonical root' ($codexConfig -match [regex]::Escape('C:\GokuCodexAI\DataIndex\minecraft-knowledge-local'))
Check 'MCP knowledge uses canonical root' ($codexConfig -match [regex]::Escape("'C:\GokuCodexAI\Data'"))

$skillCandidates = @(
    (Join-Path $PSScriptRoot '.agents\skills\legacy-java-converter-vnext\SKILL.md'),
    (Join-Path $env:USERPROFILE '.codex\skills\legacy-java-converter-vnext\SKILL.md')
)
Check 'native vNext skill discovery' (@($skillCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf }).Count -gt 0)
Check 'no duplicate nested agent tree' (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'projects\RMCodexMCConverter\.agents\.agents') -PathType Container))

$activeFiles = @('AGENTS.md','.codex\config.toml','Open-CodexRepairSession.ps1','Open-KATRepairSession.ps1','Watch-CodexGuidance.ps1','Watch-KATRepairSession.ps1','scripts\Sync-LegacyConverterWorkspace.ps1','README.md','config\gokuai.json')
$legacyRootPattern = [regex]::Escape(('C:\' + 'gokuai'))
$legacyAgentPattern = '\.' + 'grok(?:[\\/]|\b)'
$legacyRuntimePattern = ('GROK' + '_HOME|grok' + '\.exe|grok' + ' mcp')
foreach ($relative in $activeFiles) {
    $path = Join-Path $PSScriptRoot $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { Check "active file $relative" $false; continue }
    $text = Get-Content -LiteralPath $path -Raw
    Check "native dependency hygiene: $relative" ($text -notmatch "$legacyRootPattern|$legacyAgentPattern|$legacyRuntimePattern")
}

if ($failures) { Write-Host "GokuCodexAI validation failed: $failures" -ForegroundColor Red; exit 1 }
Write-Host 'GokuCodexAI Codex-first validation passed.' -ForegroundColor Green
