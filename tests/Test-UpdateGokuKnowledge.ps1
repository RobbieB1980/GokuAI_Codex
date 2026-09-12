$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "ASSERT TRUE FAILED: $Message" }
}

function Assert-Equal($Expected, $Actual, [string]$Message) {
    $expectedJson = ConvertTo-Json @($Expected) -Compress
    $actualJson = ConvertTo-Json @($Actual) -Compress
    if ($expectedJson -ne $actualJson) {
        throw "ASSERT EQUAL FAILED: $Message expected=$expectedJson actual=$actualJson"
    }
}

function Invoke-Wrapper([string]$Script, [string]$Root, [string]$Python, [string]$Report) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $Script -Root $Root -Python $Python -ReportPath $Report | Out-Host
    return $LASTEXITCODE
}

$repo = Split-Path -Parent $PSScriptRoot
$script = Join-Path $repo 'Update-GokuKnowledge.ps1'
Assert-True (Test-Path -LiteralPath $script) 'Update-GokuKnowledge.ps1 must exist'

$fixture = Join-Path ([IO.Path]::GetTempPath()) ('goku-update-test-' + [guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Path (Join-Path $fixture 'scripts'),(Join-Path $fixture 'runtime\python-mcp\Scripts'),(Join-Path $fixture 'Data'),(Join-Path $fixture 'state') -Force | Out-Null
    foreach ($name in 'update_knowledge.py','build_mapping_corpus.py','index_knowledge.py','validate_knowledge_index.py') {
        Set-Content -LiteralPath (Join-Path $fixture "scripts\$name") -Value '# fixture'
    }
    $fakePython = Join-Path $fixture 'fake-python.ps1'
    @'
$name = [IO.Path]::GetFileName($args[0])
$stage = switch ($name) {
    'update_knowledge.py' { 'sources' }
    'build_mapping_corpus.py' { 'mappings' }
    'index_knowledge.py' { 'knowledge-index' }
    'validate_knowledge_index.py' { 'validation' }
}
Add-Content -LiteralPath $env:GOKU_TEST_STAGE_LOG -Value $stage
if ($env:GOKU_TEST_FAIL_STAGE -eq $stage) { exit 7 }
if ($stage -eq 'validation') { '{"ok":true}' }
exit 0
'@ | Set-Content -LiteralPath $fakePython

    $env:GOKU_TEST_STAGE_LOG = Join-Path $fixture 'stages.log'
    $env:GOKU_TEST_FAIL_STAGE = ''
    $report = Join-Path $fixture 'success.json'
    $successExit = Invoke-Wrapper $script $fixture $fakePython $report
    Assert-Equal @('sources','mappings','knowledge-index','validation') @(Get-Content $env:GOKU_TEST_STAGE_LOG | ForEach-Object { [string]$_ }) 'successful stage order'
    Assert-Equal 0 $successExit 'successful exit code'
    Assert-Equal 'success' (Get-Content $report -Raw | ConvertFrom-Json).status 'successful report status'

    Remove-Item -LiteralPath $env:GOKU_TEST_STAGE_LOG
    $env:GOKU_TEST_FAIL_STAGE = 'mappings'
    $report = Join-Path $fixture 'failed.json'
    $failedExit = Invoke-Wrapper $script $fixture $fakePython $report
    Assert-Equal @('sources','mappings','validation') @(Get-Content $env:GOKU_TEST_STAGE_LOG | ForEach-Object { [string]$_ }) 'failed stage order'
    Assert-True ($failedExit -ne 0) 'failed stage exits non-zero'
    Assert-Equal 'failed' (Get-Content $report -Raw | ConvertFrom-Json).status 'failed report status'

    $lockPath = Join-Path $fixture 'state\knowledge-update.lock'
    $heldLock = [IO.File]::Open($lockPath, 'OpenOrCreate', 'ReadWrite', 'None')
    try {
        $report = Join-Path $fixture 'locked.json'
        $lockedExit = Invoke-Wrapper $script $fixture $fakePython $report
        Assert-True ($lockedExit -ne 0) 'overlapping run exits non-zero'
        Assert-Equal 'locked' (Get-Content $report -Raw | ConvertFrom-Json).status 'locked report status'
    } finally {
        $heldLock.Dispose()
    }

    Write-Host 'PASS: Update-GokuKnowledge orchestration tests'
} finally {
    Remove-Item Env:GOKU_TEST_STAGE_LOG -ErrorAction SilentlyContinue
    Remove-Item Env:GOKU_TEST_FAIL_STAGE -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
