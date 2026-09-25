[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ProjectPath,
    [string]$Root = 'C:\GokuCodexAI',
    [string]$DataRoot = ''
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$project = (Resolve-Path -LiteralPath $ProjectPath).Path
$python = Join-Path $Root 'runtime\python-mcp-v2\Scripts\python.exe'
if (-not (Test-Path -LiteralPath $python)) {
    $python = Join-Path $Root 'runtime\python-mcp-v2\Scripts\python.exe'
}
$script = Join-Path $Root 'scripts\generate_project_knowledge_context.py'
if (-not (Test-Path -LiteralPath $python)) { throw "Python runtime missing: $python" }
if (-not (Test-Path -LiteralPath $script)) { throw "Knowledge wiring generator missing: $script" }
$args = @($script, '--root', $Root, '--project', $project)
if ($DataRoot) { $args += @('--data-root', $DataRoot) }
& $python @args
if ($LASTEXITCODE -ne 0) { throw "Project knowledge wiring refresh failed with exit code $LASTEXITCODE" }

