<# Synchronize the active Codex-native Legacy Java Converter workspace. #>
[CmdletBinding()]
param(
    [string]$Workspace = 'C:\GokuCodexAI\projects\RMCodexMCConverter',
    [switch]$SkillsOnly,
    [string]$GokuRoot = 'C:\GokuCodexAI'
)

$ErrorActionPreference = 'Stop'
$overlay = Join-Path $GokuRoot 'tooling\legacy-converter-workspace-overlay'
$target = [IO.Path]::GetFullPath($Workspace)
if (-not (Test-Path -LiteralPath $overlay -PathType Container)) { throw "Native converter overlay missing: $overlay" }
if (-not (Test-Path -LiteralPath $target -PathType Container)) { New-Item -ItemType Directory -Path $target -Force | Out-Null }

function Copy-Native([string]$Relative) {
    $src = Join-Path $overlay $Relative
    $dst = Join-Path $target $Relative
    if (-not (Test-Path -LiteralPath $src)) { throw "Native overlay component missing: $src" }
    if ((Get-Item -LiteralPath $src).PSIsContainer) {
        New-Item -ItemType Directory -Path $dst -Force | Out-Null
        & robocopy.exe $src $dst /E /PURGE /R:1 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
        if ($LASTEXITCODE -gt 7) { throw "robocopy failed for ${Relative}: $LASTEXITCODE" }
    } else {
        $parent = Split-Path -Parent $dst
        if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        Copy-Item -LiteralPath $src -Destination $dst -Force
    }
}

Copy-Native 'AGENTS.md'
Copy-Native '.agents'
Copy-Native '.codex'
if (-not $SkillsOnly) { Copy-Native 'tools' }

$required = @('AGENTS.md','.agents\skills','.codex\config.toml')
$missing = @($required | Where-Object { -not (Test-Path -LiteralPath (Join-Path $target $_)) })
if ($missing.Count) { throw "Native converter workspace incomplete: $($missing -join ', ')" }
[pscustomobject]@{ Workspace=$target; Overlay=$overlay; Ready=$true } | ConvertTo-Json -Compress
