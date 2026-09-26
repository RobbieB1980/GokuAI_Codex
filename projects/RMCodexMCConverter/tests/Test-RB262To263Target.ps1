$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$targetRoot = Join-Path $repo 'targets\rb-26.2-to-26.3'
$manifestPath = Join-Path $targetRoot 'target-manifest.json'
$enginePath = Join-Path $targetRoot 'lib\Convert-RB262To263.ps1'
$knowledgePath = Join-Path $targetRoot 'knowledge\PrimerChangeIndex-26.2-to-26.3.json'

function Assert-True([bool]$condition, [string]$message) {
    if (-not $condition) { throw "ASSERTION FAILED: $message" }
}

Assert-True (Test-Path -LiteralPath $manifestPath) 'target manifest exists'
Assert-True (Test-Path -LiteralPath $enginePath) 'conversion engine exists'
Assert-True (Test-Path -LiteralPath $knowledgePath) 'knowledge index exists'
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
Assert-True ($manifest.source.minecraft -eq '26.2') 'source Minecraft is 26.2'
Assert-True ($manifest.target.minecraft -eq '26.3') 'target Minecraft is 26.3'
Assert-True ($manifest.target.data_pack_version -eq '121.0') 'target data pack version is 121.0'
Assert-True ($manifest.target.resource_pack_version -eq '97.1') 'target resource pack version is 97.1'
$knowledge = Get-Content -LiteralPath $knowledgePath -Raw | ConvertFrom-Json
Assert-True ($knowledge.entries.Count -ge 12) 'knowledge index has required change families'
Assert-True (($knowledge.entries | Where-Object risk -eq 'manual').Count -ge 4) 'manual repair risks are represented'

. $enginePath
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('rb262263-' + [guid]::NewGuid().ToString('N'))
$input = Join-Path $fixture 'input'
$output = Join-Path $fixture 'output'
New-Item -ItemType Directory -Path (Join-Path $input 'gradle'), (Join-Path $input 'src\main\resources\data\demo\worldgen\noise_settings') -Force | Out-Null
Set-Content -LiteralPath (Join-Path $input 'gradle.properties') -Value 'minecraft_version=26.2`nneo_version=26.2.0.72' -Encoding UTF8
Set-Content -LiteralPath (Join-Path $input 'pack.mcmeta') -Value '{"pack":{"pack_format":107,"description":"fixture"},"unknown":{"keep":true}}' -Encoding UTF8
Set-Content -LiteralPath (Join-Path $input 'src\main\resources\data\demo\worldgen\noise_settings\demo.json') -Value '{"surface_rule":{"type":"minecraft:sequence","sequence":[]},"noise_router":{"barrier":{},"lava":{}},"unknown":7}' -Encoding UTF8

$result = Invoke-RB262To263 -InputPath $input -OutputPath $output -NeoVersion '26.3.0.1-beta'
Assert-True ($result.Status -eq 'Converted') 'conversion succeeds for 26.2 input'
Assert-True (Test-Path -LiteralPath (Join-Path $output 'conversion-manifest.json')) 'conversion manifest written'
$pack = Get-Content -LiteralPath (Join-Path $output 'pack.mcmeta') -Raw | ConvertFrom-Json
Assert-True ($pack.pack.pack_format -eq 97.1) 'pack format migrated'
$worldgen = Get-Content -LiteralPath (Join-Path $output 'src\main\resources\data\demo\worldgen\noise_settings\demo.json') -Raw | ConvertFrom-Json
Assert-True ($null -ne $worldgen.material_rule) 'surface_rule migrated to material_rule'
Assert-True ($null -eq $worldgen.PSObject.Properties['surface_rule']) 'old surface_rule removed'
Assert-True ($worldgen.unknown -eq 7) 'unknown worldgen field preserved'
$second = Invoke-RB262To263 -InputPath $output -OutputPath (Join-Path $fixture 'output2') -NeoVersion '26.3.0.1-beta'
Assert-True ($second.Status -eq 'Rejected') 'already-26.3 output is rejected as input'

try { Invoke-RB262To263 -InputPath $input -OutputPath $input; throw 'same input/output was accepted' } catch { Assert-True ($_.Exception.Message -match 'different') 'same path rejected' }
Remove-Item -LiteralPath $fixture -Recurse -Force
Write-Host 'RB 26.2 -> 26.3 target tests passed' -ForegroundColor Green
