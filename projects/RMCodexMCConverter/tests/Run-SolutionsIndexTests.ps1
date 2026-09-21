[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
. (Join-Path $repo 'lib\SolutionsIndex.ps1')
$script:passed = 0
function Assert-True([bool]$Condition, [string]$Name) { if (-not $Condition) { throw "Assertion failed: $Name" }; $script:passed++ }
$index = Read-SolutionsIndex
$evidence = Get-SolutionsIndexEvidence -ModId 'nextgen_furniture' -SourceVersion '1.21.1' -Index $index
Assert-True $evidence.consulted 'index consulted'
Assert-True ($evidence.matches.Count -gt 0) 'known solution matched'
Assert-True ($evidence.nextStage -eq 'apply_known_solution') 'known solution is next stage'
$miss = Get-SolutionsIndexEvidence -ModId 'unknown_mod' -SourceVersion '1.20.1' -Index $index
Assert-True ($miss.matches.Count -eq 0) 'unknown solution has no match'
Assert-True ($miss.nextStage -eq 'exact_version_evidence') 'unknown solution escalates deterministically'
Write-Host "Solutions Index tests passed: $script:passed" -ForegroundColor Green
