[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Root,
    [Parameter(Mandatory)][string]$ManifestPath,
    [ValidateSet('Repository', 'Portable')][string]$Layout = 'Portable'
)

$ErrorActionPreference = 'Stop'
$resolvedRoot = (Resolve-Path -LiteralPath $Root).Path
$resolvedManifest = (Resolve-Path -LiteralPath $ManifestPath).Path
$manifest = Get-Content -LiteralPath $resolvedManifest -Raw | ConvertFrom-Json
if ($manifest.schemaVersion -ne 1) { throw "Unsupported portable manifest schema: $($manifest.schemaVersion)" }

$missing = New-Object Collections.Generic.List[string]
foreach ($entry in @($manifest.entries)) {
    $relative = if ($Layout -eq 'Repository') { [string]$entry.sourcePath } else { [string]$entry.destinationPath }
    if ([string]::IsNullOrWhiteSpace($relative)) { continue }
    $candidate = Join-Path $resolvedRoot ($relative -replace '/', '\')
    if ($entry.kind -eq 'directory') {
        if (-not (Test-Path -LiteralPath $candidate -PathType Container)) {
            $missing.Add($relative) | Out-Null
            continue
        }
        if ($entry.recursive -and -not (Get-ChildItem -LiteralPath $candidate -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1)) {
            $missing.Add("$relative (empty)") | Out-Null
        }
    } elseif (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
        $missing.Add($relative) | Out-Null
    }
}

if ($missing.Count -gt 0) {
    [Console]::Error.WriteLine("Missing required ${Layout} paths:")
    foreach ($path in $missing) { [Console]::Error.WriteLine("- $path") }
    exit 1
}

Write-Host "Portable manifest valid for $Layout layout: $resolvedRoot" -ForegroundColor Green
