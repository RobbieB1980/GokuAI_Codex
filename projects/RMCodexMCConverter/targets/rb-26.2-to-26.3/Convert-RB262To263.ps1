[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$InputPath,
    [Parameter(Mandatory)][string]$OutputPath,
    [Parameter(Mandatory)][string]$NeoVersion
)
. (Join-Path $PSScriptRoot 'lib\Convert-RB262To263.ps1')
Invoke-RB262To263 -InputPath $InputPath -OutputPath $OutputPath -NeoVersion $NeoVersion | ConvertTo-Json -Depth 20
