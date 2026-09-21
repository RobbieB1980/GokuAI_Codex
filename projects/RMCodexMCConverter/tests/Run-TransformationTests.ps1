[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
. (Join-Path $PSScriptRoot 'TestHelpers.ps1')
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('legacy-load-only-test-' + [guid]::NewGuid().ToString('N'))
$source = Join-Path $fixture 'source'
$output = Join-Path $fixture 'output'
$marker = Join-Path $fixture 'loaded.txt'
$driver = Join-Path $fixture 'driver.ps1'

try {
    New-Item -ItemType Directory -Path (Join-Path $source 'src\main\java\example') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $source 'gradle.properties') -Value "minecraft_version=1.20.1`nforge_version=47.4.0" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $source 'src\main\java\example\Example.java') -Value 'package example; class Example {}' -Encoding UTF8
    $driverBody = @"
`$ErrorActionPreference = 'Stop'
`$env:LEGACY_CONVERTER_LOAD_ONLY = '1'
. '$($repo.Replace("'", "''"))\Convert-Forge1201-ToNeoForge262.ps1' -Path '$($source.Replace("'", "''"))' -OutputPath '$($output.Replace("'", "''"))' -SkipDependencyDownload -SkipDependencyConvert
if (Get-Command Invoke-MechanicalJavaRewrites -ErrorAction SilentlyContinue) {
    Set-Content -LiteralPath '$($marker.Replace("'", "''"))' -Value 'loaded' -Encoding ASCII
}
"@
    Set-Content -LiteralPath $driver -Value $driverBody -Encoding UTF8
    & powershell -NoProfile -ExecutionPolicy Bypass -File $driver | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "load-only child failed with exit $LASTEXITCODE" }
    if (-not (Test-Path -LiteralPath $marker)) { throw 'load-only did not expose converter functions' }
    if (Test-Path -LiteralPath $output) { throw 'load-only created an output directory' }
}
finally {
    Remove-Item Env:\LEGACY_CONVERTER_LOAD_ONLY -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}

$env:LEGACY_CONVERTER_LOAD_ONLY = '1'
try {
    . (Join-Path $repo 'Convert-Forge1201-ToNeoForge262.ps1') -Path $repo -OutputPath (Join-Path $fixture 'unused') -SkipDependencyDownload -SkipDependencyConvert
    $mechanicalTransform = {
        param([string]$ProjectRoot)
        $null = Invoke-MechanicalJavaRewrites -Root $ProjectRoot -ModId 'example'
    }
    Assert-TextFixture -Transform $mechanicalTransform -FixtureRoot (Join-Path $PSScriptRoot 'fixtures\mechanical\resource-location') -Name 'resource location migration'
    Assert-TextFixture -Transform $mechanicalTransform -FixtureRoot (Join-Path $PSScriptRoot 'fixtures\mechanical\comment-and-string') -Name 'legacy comment and string boundary'
}
finally {
    Remove-Item Env:\LEGACY_CONVERTER_LOAD_ONLY -ErrorAction SilentlyContinue
}

Write-Host 'Transformation tests passed: 3' -ForegroundColor Green
