[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$workerRoot = Join-Path $repo 'tools\lib\ast-worker'
$bridgePath = Join-Path $repo 'lib\AstWorkerBridge.ps1'
$passed = 0

function Assert-True([bool]$Condition, [string]$Name) {
    if (-not $Condition) { throw "FAILED: $Name" }
    $script:passed++
}

function Assert-Equal($Actual, $Expected, [string]$Name) {
    if ($Actual -ne $Expected) { throw "FAILED: $Name (expected '$Expected', got '$Actual')" }
    $script:passed++
}

if (-not (Test-Path -LiteralPath $workerRoot -PathType Container)) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo 'tools\Build-AstWorker.ps1') | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "AST worker build failed with exit $LASTEXITCODE" }
}

. $bridgePath

$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ('legacy ast bridge source ' + [guid]::NewGuid().ToString('N'))
try {
    $validRoot = Join-Path $fixtureRoot 'valid source'
    $mixedRoot = Join-Path $fixtureRoot 'mixed source'
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'fixtures\ast-analysis\valid') -Destination $validRoot -Recurse
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'fixtures\ast-analysis\mixed') -Destination $mixedRoot -Recurse

    $beforeHash = (Get-FileHash -LiteralPath (Join-Path $validRoot 'Example.java') -Algorithm SHA256).Hash
    $valid = Invoke-LegacyAstWorker -SourceRoot $validRoot -Classpath @() -WorkerRoot $workerRoot
    $afterHash = (Get-FileHash -LiteralPath (Join-Path $validRoot 'Example.java') -Algorithm SHA256).Hash
    Assert-Equal $valid.status 'ok' 'valid worker response status'
    Assert-True (@($valid.parsedFiles) -contains 'Example.java') 'source path containing spaces reaches worker through JSON stdin'
    Assert-True (@($valid.declaredTypes) -contains 'example.Example') 'UTF-8 source parses through bridge'
    Assert-True (@($valid.imports) -contains 'java.util.List') 'valid response inventory parsed'
    Assert-Equal $afterHash $beforeHash 'analysis does not modify UTF-8 source'

    $mismatch = '{"protocolVersion":2,"status":"ok","parsedFiles":[],"parseFailures":[],"declaredTypes":[],"imports":[],"diagnostics":[]}'
    $mismatchMessage = ''
    try { $null = ConvertFrom-LegacyAstWorkerProcessResult -ExitCode 0 -Stdout $mismatch -Stderr '' }
    catch { $mismatchMessage = $_.Exception.Message }
    Assert-True ($mismatchMessage -match 'protocol') 'protocol mismatch is rejected'

    $failure = '{"protocolVersion":1,"status":"worker_error","parsedFiles":[],"parseFailures":[],"declaredTypes":[],"imports":[],"diagnostics":["source root unavailable"]}'
    $failureMessage = ''
    try { $null = ConvertFrom-LegacyAstWorkerProcessResult -ExitCode 3 -Stdout $failure -Stderr 'worker stderr' }
    catch { $failureMessage = $_.Exception.Message }
    Assert-True ($failureMessage -match 'exit 3') 'nonzero worker exit is rejected'
    Assert-True ($failureMessage -match 'source root unavailable') 'nonzero worker diagnostics are preserved'

    $mixed = Invoke-LegacyAstWorker -SourceRoot $mixedRoot -Classpath @() -WorkerRoot $workerRoot
    Assert-Equal @($mixed.parseFailures).Count 1 'parse failure returned through bridge'
    Assert-Equal $mixed.parseFailures[0].path 'Broken.java' 'parse failure relative path preserved'
    Assert-True (@($mixed.parseFailures[0].problems).Count -gt 0) 'parse failure diagnostics preserved'

    $comparison = Compare-LegacyAndAstInventory -SourceRoot $mixedRoot -AstResult $mixed
    Assert-True (@($comparison.MissingFromAst) -contains 'type:sample.Broken') 'shadow comparison reports regex-only broken type'
    Assert-Equal @($comparison.MissingFromAst).Count 1 'shadow comparison excludes nested types from top-level inventory'
    Assert-Equal @($comparison.OnlyInAst).Count 0 'shadow comparison has no unexpected AST-only entries'
    Assert-Equal @($comparison.ParseFailures).Count 1 'shadow comparison carries parse failures'
}
finally {
    if (Test-Path -LiteralPath $fixtureRoot) { Remove-Item -LiteralPath $fixtureRoot -Recurse -Force }
}

Write-Host "AST bridge tests passed: $passed" -ForegroundColor Green
