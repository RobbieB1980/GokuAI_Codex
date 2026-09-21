[CmdletBinding()]
param([string]$ProjectRoot)

$canonical = Join-Path $PSScriptRoot '..\..\Lint-MigrationSkills.ps1'
if (-not (Test-Path -LiteralPath $canonical -PathType Leaf)) {
    throw 'Canonical Lint-MigrationSkills.ps1 was not packaged into the workspace tools directory.'
}
& $canonical -ProjectRoot $ProjectRoot
exit $LASTEXITCODE
