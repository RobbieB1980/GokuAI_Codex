[CmdletBinding()]
param(
    [string]$Root,
    [string]$Python,
    [switch]$ReleaseOnly,
    [switch]$IncludeServerJar,
    [switch]$SkipSourceUpdate,
    [string]$ReportPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($Root)) {
    $Root = $PSScriptRoot
}
$Root = [IO.Path]::GetFullPath($Root)
if ([string]::IsNullOrWhiteSpace($Python)) {
    $Python = Join-Path $Root 'runtime\python-mcp-v2\Scripts\python.exe'
}
$dataRoot = Join-Path $Root 'Data'
$indexRoot = Join-Path $Root 'DataIndex\minecraft-knowledge-local'
$mappingRoot = Join-Path $dataRoot 'Minecraft_Mappings_Corpus'
$stateRoot = Join-Path $Root 'state'
$started = Get-Date
if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $stamp = $started.ToString('yyyyMMdd-HHmmss')
    $ReportPath = Join-Path $Root "logs\knowledge-update\update-$stamp.json"
}
$ReportPath = [IO.Path]::GetFullPath($ReportPath)

function Write-AtomicJson([string]$Path, $Value) {
    $parent = Split-Path -Parent $Path
    if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    $part = "$Path.part"
    $Value | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $part -Encoding UTF8
    Move-Item -LiteralPath $part -Destination $Path -Force
}

function New-Report([string]$Status) {
    [ordered]@{
        schema = 'goku-knowledge-update-v1'
        status = $Status
        started = $started.ToString('o')
        finished = $null
        duration_seconds = $null
        arguments = [ordered]@{
            release_only = [bool]$ReleaseOnly
            include_server_jar = [bool]$IncludeServerJar
            skip_source_update = [bool]$SkipSourceUpdate
        }
        stages = @()
        active_databases = [ordered]@{
            mappings = $null
            knowledge = $null
        }
        validation = $null
        error = $null
    }
}

function Invoke-PythonStage([string]$Name, [string[]]$Arguments) {
    $stageStarted = Get-Date
    Write-Host ("==> {0}" -f $Name) -ForegroundColor Cyan
    $output = (& $Python @Arguments 2>&1 | Out-String).Trim()
    $code = $LASTEXITCODE
    $stageFinished = Get-Date
    [ordered]@{
        name = $Name
        status = if ($code -eq 0) { 'success' } else { 'failed' }
        exit_code = $code
        started = $stageStarted.ToString('o')
        finished = $stageFinished.ToString('o')
        duration_seconds = [math]::Round(($stageFinished - $stageStarted).TotalSeconds, 3)
        output = $output
        command = @($Python) + $Arguments
    }
}

$report = New-Report 'running'
New-Item -ItemType Directory -Path $stateRoot -Force | Out-Null
$lock = $null
try {
    try {
        $lock = [IO.File]::Open((Join-Path $stateRoot 'knowledge-update.lock'),
            [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    } catch [IO.IOException] {
        $report.status = 'locked'
        $report.error = 'Another knowledge update is already running.'
        $finished = Get-Date
        $report.finished = $finished.ToString('o')
        $report.duration_seconds = [math]::Round(($finished - $started).TotalSeconds, 3)
        Write-AtomicJson $ReportPath $report
        [Console]::Error.WriteLine($report.error)
        exit 2
    }

    if (-not (Test-Path -LiteralPath $Python)) { throw "Python runtime not found: $Python" }
    $failed = $false

    if ($SkipSourceUpdate) {
        $report.stages += [ordered]@{ name='sources'; status='skipped'; exit_code=0; output='Using current local sources.' }
    } else {
        $args = @((Join-Path $Root 'scripts\update_knowledge.py'), '--root', $dataRoot)
        if ($ReleaseOnly) { $args += '--release-only' }
        if ($IncludeServerJar) { $args += '--include-server-jar' }
        $stage = Invoke-PythonStage 'sources' $args
        $report.stages += $stage
        $failed = $stage.exit_code -ne 0
    }

    if (-not $failed) {
        $args = @((Join-Path $Root 'scripts\build_mapping_corpus.py'), '--data-root', $dataRoot,
                  '--output-root', $mappingRoot)
        $stage = Invoke-PythonStage 'mappings' $args
        $report.stages += $stage
        $failed = $stage.exit_code -ne 0
    }

    if (-not $failed) {
        New-Item -ItemType Directory -Path $indexRoot -Force | Out-Null
        $args = @((Join-Path $Root 'scripts\index_knowledge.py'), '--root', $dataRoot,
                  '--db', (Join-Path $indexRoot 'knowledge.db'),
                  '--sources-manifest', (Join-Path $dataRoot 'external_sources.json'))
        $stage = Invoke-PythonStage 'knowledge-index' $args
        $report.stages += $stage
        $failed = $stage.exit_code -ne 0
    }

    $validationJson = "$ReportPath.validation.json"
    $args = @((Join-Path $Root 'scripts\validate_knowledge_index.py'),
              '--station-root', $Root, '--data-root', $dataRoot,
              '--knowledge-db', (Join-Path $indexRoot 'knowledge.db'),
              '--mapping-db', (Join-Path $mappingRoot 'mappings.db'),
              '--json-out', $validationJson)
    $validationStage = Invoke-PythonStage 'validation' $args
    $report.stages += $validationStage
    if (Test-Path -LiteralPath $validationJson) {
        $report.validation = Get-Content -LiteralPath $validationJson -Raw | ConvertFrom-Json
        Remove-Item -LiteralPath $validationJson -Force
    }
    if ($validationStage.exit_code -ne 0) { $failed = $true }

    foreach ($item in @(@('mappings',$mappingRoot), @('knowledge',$indexRoot))) {
        $pointer = Join-Path $item[1] '_ACTIVE_DB.txt'
        if (Test-Path -LiteralPath $pointer) {
            $name = (Get-Content -LiteralPath $pointer -Raw).Trim()
            $report.active_databases[$item[0]] = if ([IO.Path]::IsPathRooted($name)) { $name } else { Join-Path $item[1] $name }
        }
    }
    $report.status = if ($failed) { 'failed' } else { 'success' }
    $finished = Get-Date
    $report.finished = $finished.ToString('o')
    $report.duration_seconds = [math]::Round(($finished - $started).TotalSeconds, 3)
    Write-AtomicJson $ReportPath $report
    Write-Host ("Knowledge update {0}. Report: {1}" -f $report.status, $ReportPath) -ForegroundColor $(if ($failed) { 'Red' } else { 'Green' })
    if ($failed) { exit 1 }
    exit 0
} catch {
    $report.status = 'failed'
    $report.error = $_.Exception.Message
    $finished = Get-Date
    $report.finished = $finished.ToString('o')
    $report.duration_seconds = [math]::Round(($finished - $started).TotalSeconds, 3)
    Write-AtomicJson $ReportPath $report
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
} finally {
    if ($null -ne $lock) { $lock.Dispose() }
}
