<#
.SYNOPSIS
  Validate the native Codex migration skills and their local references.
#>
[CmdletBinding()]
param(
    [string]$ProjectRoot,
    [string]$KnowledgeRoot = 'C:\GokuCodexAI\Data'
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
}
$ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$overlay = Join-Path $ProjectRoot 'gokuai-workspace-overlay'
$workspace = if (Test-Path -LiteralPath (Join-Path $ProjectRoot '.agents\skills')) { $ProjectRoot } elseif (Test-Path -LiteralPath (Join-Path $overlay '.agents\skills')) { $overlay } else { $ProjectRoot }
$skills = Join-Path $workspace '.agents\skills'
$failures = [Collections.Generic.List[string]]::new()
$legacyProjectConfig = '.' + 'grok'
$legacyProjectConfigPattern = '\.' + 'grok[\\/]'

function Add-Failure([string]$Message) { $failures.Add($Message) | Out-Null }

foreach ($required in @('AGENTS.md', '.agents\skills', '.codex\config.toml')) {
    if (-not (Test-Path -LiteralPath (Join-Path $workspace $required))) {
        Add-Failure "Missing native Codex workspace entry: $required"
    }
}
if (Test-Path -LiteralPath (Join-Path $workspace $legacyProjectConfig)) {
    Add-Failure 'Legacy project discovery directory is present'
}

$requiredSkills = @(
    'legacy-java-converter-vnext',
    'repair-failed-262-output',
    'encode-262r-remap',
    'validate-destination-build'
)
foreach ($name in $requiredSkills) {
    $skillPath = Join-Path $skills "$name\SKILL.md"
    if (-not (Test-Path -LiteralPath $skillPath -PathType Leaf)) {
        Add-Failure "Missing skill: $name"
        continue
    }
    $text = Get-Content -LiteralPath $skillPath -Raw
    if ($text -notmatch '(?ms)\A---\s*\r?\n.*?^name:\s*[^\r\n]+') { Add-Failure "$name has no front-matter name" }
    if ($text -notmatch '(?ms)\A---\s*\r?\n.*?^description:\s*') { Add-Failure "$name has no front-matter description" }
    if (($text -split "`n").Count -gt 200) { Add-Failure "$name SKILL.md exceeds 200 lines" }
    if ($text -match $legacyProjectConfigPattern) { Add-Failure "$name contains a legacy project-config reference" }
    foreach ($match in [regex]::Matches($text, '\]\((references/[^)#]+)')) {
        $reference = Join-Path (Split-Path -Parent $skillPath) ($match.Groups[1].Value.Replace('/', '\'))
        if (-not (Test-Path -LiteralPath $reference -PathType Leaf)) {
            Add-Failure "$name references missing file: $($match.Groups[1].Value)"
        }
    }
}
foreach ($name in @('minecraft-knowledge', 'migrate-neoforge-262')) {
    if (Test-Path -LiteralPath (Join-Path $skills $name) -PathType Container) {
        Add-Failure "Obsolete skill remains: $name"
    }
}

$catalogCandidates = @(
    (Join-Path $ProjectRoot 'knowledge-backup\262r\catalog.json'),
    (Join-Path $KnowledgeRoot '262r\catalog.json')
)
$catalogPath = $catalogCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
if (-not $catalogPath) {
    Add-Failure "Missing 262r catalog; checked: $($catalogCandidates -join ', ')"
} else {
    $catalog = Get-Content -LiteralPath $catalogPath -Raw | ConvertFrom-Json
    $ids = [Collections.Generic.HashSet[string]]::new()
    foreach ($row in @($catalog.converter) + @($catalog.shards)) { if ($row.id) { [void]$ids.Add([string]$row.id) } }
    $indexPath = Join-Path $skills 'repair-failed-262-output\references\262r-shard-index.md'
    if (-not (Test-Path -LiteralPath $indexPath -PathType Leaf)) {
        Add-Failure 'Missing 262r-shard-index.md'
    } else {
        $indexText = Get-Content -LiteralPath $indexPath -Raw
        foreach ($match in [regex]::Matches($indexText, 'mc-262r-[a-z0-9-]+')) {
            if (-not $ids.Contains($match.Value)) { Add-Failure "Shard index references unknown id: $($match.Value)" }
        }
    }
}

if ($failures.Count -gt 0) {
    Write-Host "Native skill lint failed: $($failures.Count)" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host " - $_" }
    exit 1
}

Write-Host "Native skill lint passed: $($requiredSkills.Count) skills" -ForegroundColor Green
