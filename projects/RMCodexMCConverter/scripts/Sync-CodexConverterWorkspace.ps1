<#
.SYNOPSIS
  Synchronize the versioned native Codex repair bundle into a workspace.
#>
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

function Assert-RequiredFile([string]$Path, [string]$RelativeName) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Missing required native repair component: $RelativeName"
    }
}

function Copy-TreeChecked([string]$Source, [string]$Destination, [string]$Label) {
    if (-not (Test-Path -LiteralPath $Source -PathType Container)) { throw "Missing $Label source: $Source" }
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    & robocopy.exe $Source $Destination /E /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -gt 7) { throw "robocopy $Label failed: $LASTEXITCODE" }
}

function Resolve-Bundle([string]$Root, [string]$ExplicitOverlay) {
    $here = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
    $candidates = [Collections.Generic.List[string]]::new()
    if ($Root) { $candidates.Add([IO.Path]::GetFullPath($Root)) }
    $candidates.Add([IO.Path]::GetFullPath((Join-Path $here '..')))
    $candidates.Add([IO.Path]::GetFullPath($here))
    foreach ($candidate in $candidates | Select-Object -Unique) {
        $toolRoot = if (Test-Path -LiteralPath (Join-Path $candidate 'tools\gokuai-workspace-overlay')) { Join-Path $candidate 'tools' } else { $candidate }
        $overlay = if ($ExplicitOverlay) { [IO.Path]::GetFullPath($ExplicitOverlay) } else { Join-Path $toolRoot 'gokuai-workspace-overlay' }
        if (Test-Path -LiteralPath (Join-Path $overlay '.agents\skills') -PathType Container) {
            return [pscustomobject]@{
                Root = $candidate
                ToolRoot = $toolRoot
                Overlay = $overlay
                Repository = (Test-Path -LiteralPath (Join-Path $candidate 'lib\ConversionCore.ps1') -PathType Leaf)
            }
        }
        if ($ExplicitOverlay) { break }
    }
    throw 'Converter repair bundle not found. Expected gokuai-workspace-overlay with .agents\skills.'
}

function Resolve-KnowledgeDatabase([string]$Root) {
    foreach ($directory in @(
        (Join-Path $Root 'DataIndex\minecraft-knowledge-local'),
        (Join-Path $Root 'DataIndex\minecraft-knowledge')
    )) {
        $pointer = Join-Path $directory '_ACTIVE_DB.txt'
        if (Test-Path -LiteralPath $pointer -PathType Leaf) {
            $name = (Get-Content -LiteralPath $pointer -Raw).Trim()
            $candidate = Join-Path $directory $name
            if (Test-Path -LiteralPath $candidate -PathType Leaf) { return (Resolve-Path -LiteralPath $candidate).Path }
        }
        $candidate = Get-ChildItem -LiteralPath $directory -Filter 'knowledge*.db' -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
        if ($candidate) { return $candidate.FullName }
    }
    throw "No active Minecraft knowledge database found under $Root\DataIndex"
}

function ConvertTo-TomlBasicString([string]$Value) {
    return $Value.Replace('\', '\\').Replace('"', '\"')
}

$bundle = Resolve-Bundle -Root $RepoRoot -ExplicitOverlay $OverlayRoot
$overlay = $bundle.Overlay
$requiredOverlay = @(
    'AGENTS.md',
    '.codex\config.toml',
    '.agents\skills\legacy-java-converter-vnext\SKILL.md',
    '.agents\skills\repair-failed-262-output\SKILL.md'
)
foreach ($relative in $requiredOverlay) { Assert-RequiredFile (Join-Path $overlay $relative) $relative }

$GokuRoot = (Resolve-Path -LiteralPath $GokuRoot).Path
$python = Join-Path $GokuRoot 'runtime\python-mcp-v2\Scripts\python.exe'
$mcpScript = Join-Path $GokuRoot 'scripts\knowledge_mcp_v2.py'
$knowledgeRoot = Join-Path $GokuRoot 'Data'
$knowledgeDb = Resolve-KnowledgeDatabase $GokuRoot
Assert-RequiredFile $python 'runtime\python-mcp-v2\Scripts\python.exe'
Assert-RequiredFile $mcpScript 'scripts\knowledge_mcp_v2.py'
if (-not (Test-Path -LiteralPath $knowledgeRoot -PathType Container)) { throw "Missing knowledge root: $knowledgeRoot" }

New-Item -ItemType Directory -Path $Workspace -Force | Out-Null
$Workspace = (Resolve-Path -LiteralPath $Workspace).Path
Write-Host "==> Syncing native Codex repair bundle -> $Workspace" -ForegroundColor Cyan
Copy-TreeChecked (Join-Path $overlay '.agents') (Join-Path $Workspace '.agents') '.agents skills'
Copy-Item -LiteralPath (Join-Path $overlay 'AGENTS.md') -Destination (Join-Path $Workspace 'AGENTS.md') -Force

$codexDir = Join-Path $Workspace '.codex'
New-Item -ItemType Directory -Path $codexDir -Force | Out-Null
$config = Get-Content -LiteralPath (Join-Path $overlay '.codex\config.toml') -Raw
$config = $config.Replace('__GOKU_PYTHON__', (ConvertTo-TomlBasicString $python))
$config = $config.Replace('__KNOWLEDGE_MCP__', (ConvertTo-TomlBasicString $mcpScript))
$config = $config.Replace('__KNOWLEDGE_DB__', (ConvertTo-TomlBasicString $knowledgeDb))
$config = $config.Replace('__KNOWLEDGE_ROOT__', (ConvertTo-TomlBasicString $knowledgeRoot))
$config = $config.Replace('__GOKU_ROOT__', (ConvertTo-TomlBasicString $GokuRoot))
[IO.File]::WriteAllText((Join-Path $codexDir 'config.toml'), $config.TrimEnd() + "`r`n", [Text.UTF8Encoding]::new($false))

$toolsDestination = Join-Path $Workspace 'tools'
New-Item -ItemType Directory -Path $toolsDestination -Force | Out-Null
$toolNames = @('Build-WithDestinationJava.ps1', 'Lint-MigrationSkills.ps1')
if (-not $SkillsOnly) {
    $toolNames += @('Convert-Forge1201-ToNeoForge262.ps1', 'Convert-JarToProject.ps1', 'Convert-OldJarToNeoForge262.ps1')
}
foreach ($name in $toolNames) {
    $source = @(
        (Join-Path $bundle.ToolRoot $name),
        (Join-Path $overlay "tools\$name")
    ) | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
    if (-not $source) { throw "Missing required repair tool: $name" }
    Copy-Item -LiteralPath $source -Destination (Join-Path $toolsDestination $name) -Force
}
Copy-Item -LiteralPath $MyInvocation.MyCommand.Path -Destination (Join-Path $toolsDestination 'Sync-CodexConverterWorkspace.ps1') -Force

if (-not $SkillsOnly) {
    $sourceLib = if ($bundle.Repository) { Join-Path $bundle.Root 'lib' } else { Join-Path $bundle.ToolRoot 'lib' }
    $sourceAst = if ($bundle.Repository) { Join-Path $bundle.Root 'tools\lib\ast-worker' } else { Join-Path $sourceLib 'ast-worker' }
    foreach ($relative in @('ConversionCore.ps1', 'ConversionManifest.ps1', 'SolutionsIndex.ps1', 'AstWorkerBridge.ps1', 'SolvedConversionIndex.json')) {
        Assert-RequiredFile (Join-Path $sourceLib $relative) "lib\$relative"
    }
    Copy-TreeChecked $sourceLib (Join-Path $toolsDestination 'lib') 'repair libraries'
    Copy-TreeChecked $sourceAst (Join-Path $toolsDestination 'lib\ast-worker') 'JavaParser AST worker'
}

$requiredDestination = @(
    'AGENTS.md',
    '.codex\config.toml',
    '.agents\skills\legacy-java-converter-vnext\SKILL.md',
    '.agents\skills\repair-failed-262-output\SKILL.md',
    'tools\Build-WithDestinationJava.ps1',
    'tools\Lint-MigrationSkills.ps1'
)
if (-not $SkillsOnly) { $requiredDestination += @('tools\lib\ConversionManifest.ps1', 'tools\lib\SolutionsIndex.ps1', 'tools\lib\AstWorkerBridge.ps1') }
foreach ($relative in $requiredDestination) { Assert-RequiredFile (Join-Path $Workspace $relative) $relative }

$unresolved = Select-String -LiteralPath (Join-Path $Workspace '.codex\config.toml') -Pattern '__[A-Z_]+__'
if ($unresolved) { throw "Unresolved MCP template placeholder: $($unresolved.Line.Trim())" }

$result = [pscustomobject]@{
    Workspace = $Workspace
    OverlaySource = $overlay
    FilesVerified = $requiredDestination.Count
    SkillVersion = 'legacy-java-converter-vnext'
    Ready = $true
    Mode = if ($SkillsOnly) { 'skills-only' } else { 'full' }
}
Write-Host "OK: native Codex repair bundle synchronized and verified ($($result.Mode))." -ForegroundColor Green
if ($PrepareOnly) {
    $result | ConvertTo-Json -Compress
    exit 0
}
return $result
