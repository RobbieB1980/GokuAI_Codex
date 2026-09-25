[CmdletBinding()]
param(
    [string]$Root = 'C:\GokuCodexAI\Data',
    [string]$Output = 'C:\GokuCodexAI\DataIndex\goku-data.db',
    [switch]$Rebuild
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Write-Host "NOTE: goku-data.db is legacy/benchmark-only. Canonical index: DataIndex\minecraft-knowledge-local + knowledge_mcp." -ForegroundColor Yellow
$python = 'C:\GokuCodexAI\runtime\python-mcp-v2\Scripts\python.exe'
$script = 'C:\GokuCodexAI\scripts\index_goku_data.py'
if (-not (Test-Path $python)) { throw "Python missing: $python" }
if (-not (Test-Path $script)) { throw "Indexer missing: $script" }
$a = @($script, '--root', $Root, '--out', $Output)
if ($Rebuild) { $a += '--rebuild' }
& $python @a
if ($LASTEXITCODE -ne 0) { throw "Indexer failed with exit $LASTEXITCODE" }
Write-Host "Legacy index ready: $Output" -ForegroundColor Green

