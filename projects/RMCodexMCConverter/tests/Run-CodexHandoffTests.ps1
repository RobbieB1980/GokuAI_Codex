[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
. (Join-Path $repo 'lib\ConversionCore.ps1')

$script:passed = 0
function Assert-True([bool]$Condition, [string]$Name) {
    if (-not $Condition) { throw "${Name}: condition was false" }
    $script:passed++
}
function Assert-Contains([string]$Text, [string]$Expected, [string]$Name) {
    if (-not $Text.Contains($Expected)) { throw "${Name}: missing [$Expected]" }
    $script:passed++
}
function Assert-NotContains([string]$Text, [string]$Unexpected, [string]$Name) {
    if ($Text.Contains($Unexpected)) { throw "${Name}: unexpectedly contained [$Unexpected]" }
    $script:passed++
}
function Assert-Equal($Actual, $Expected, [string]$Name) {
    if ($Actual -ne $Expected) { throw "${Name}: expected [$Expected], got [$Actual]" }
    $script:passed++
}
function Assert-FileDoesNotContain([string]$Path, [string]$Unexpected, [string]$Name) {
    Assert-True (Test-Path -LiteralPath $Path -PathType Leaf) "$Name file exists"
    Assert-NotContains (Get-Content -LiteralPath $Path -Raw) $Unexpected $Name
}
function Get-TreeHash([string]$Path) {
    return @(
        Get-ChildItem -LiteralPath $Path -Recurse -File |
            Sort-Object FullName |
            ForEach-Object { '{0}:{1}' -f $_.FullName.Substring($Path.Length), (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
    ) -join "`n"
}

$fixture = Join-Path ([IO.Path]::GetTempPath()) ('legacy codex handoff ' + [guid]::NewGuid().ToString('N'))
try {
    $overlay = Join-Path $repo 'gokuai-workspace-overlay'
    Assert-True (Test-Path -LiteralPath (Join-Path $overlay 'AGENTS.md')) 'native root guidance'
    Assert-True (Test-Path -LiteralPath (Join-Path $overlay '.agents\skills\legacy-java-converter-vnext\SKILL.md')) 'vNext skill'
    Assert-True (Test-Path -LiteralPath (Join-Path $overlay '.agents\skills\repair-failed-262-output\SKILL.md')) 'repair skill'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $overlay '.agents\skills\minecraft-knowledge'))) 'MCP does not ship a duplicate knowledge skill'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $overlay '.agents\skills\migrate-neoforge-262'))) 'obsolete migration skill is pruned'
    Assert-True (Test-Path -LiteralPath (Join-Path $overlay '.codex\config.toml')) 'project MCP config'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $overlay '.grok'))) 'legacy overlay removed'

    New-Item -ItemType Directory -Path $fixture -Force | Out-Null
    $body = Get-CodexRepairRequestBody -FailedOutput $fixture -DestinationJavaMajor 25 -TargetMinecraft '26.2'
    Assert-Contains $body 'Codex is the repair orchestrator' 'orchestrator authority'
    Assert-Contains $body 'legacy-java-converter-vnext' 'native vNext skill'
    Assert-Contains $body '.agents/skills' 'native repository skill location'
    Assert-Contains $body '.codex/config.toml' 'native MCP configuration'
    Assert-Contains $body 'Solutions Index' 'known solution stage'
    Assert-Contains $body 'Build-WithDestinationJava.ps1' 'destination Java build'
    Assert-Contains $body 'runtime' 'runtime validation remains separate'
    Assert-Contains $body 'assets, models, items, entities, AI, and behaviour' 'preservation scope'
    Assert-NotContains $body 'GROK_HOME' 'no Grok environment'
    Assert-NotContains $body '.grok/' 'no Grok project configuration'

    $request = Write-CodexRepairRequest -FailedOutput $fixture -DestinationJavaMajor 25 -TargetMinecraft '26.2'
    Assert-Equal (Split-Path -Leaf $request) 'CODEX_REPAIR_REQUEST.md' 'native request filename'
    Assert-True (Test-Path -LiteralPath $request -PathType Leaf) 'native request written'
    Assert-Contains (Get-Content -LiteralPath $request -Raw) 'Codex is the repair orchestrator' 'written request content'

    $workspace = Join-Path $fixture 'repair workspace'
    $sentinel = Join-Path $workspace 'src\main\java\UserFile.java'
    New-Item -ItemType Directory -Path (Split-Path -Parent $sentinel) -Force | Out-Null
    Set-Content -LiteralPath $sentinel -Value 'class UserFile {}' -Encoding UTF8
    $gokuRoot = Join-Path $fixture 'fake GokuCodexAI'
    New-Item -ItemType Directory -Path (Join-Path $gokuRoot 'runtime\python-mcp-v2\Scripts'), (Join-Path $gokuRoot 'scripts'), (Join-Path $gokuRoot 'Data'), (Join-Path $gokuRoot 'DataIndex\minecraft-knowledge-local') -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $gokuRoot 'config') -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $gokuRoot 'config\gokuai.json') -Value '{"codex_orchestrator":{"primary":{"label":"Luna High","model":"gpt-5.6-luna-high","reasoning_effort":"high"},"fallback":{"label":"Sol Medium","model":"gpt-5.6-sol-medium","reasoning_effort":"medium"}}}' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $gokuRoot 'runtime\python-mcp-v2\Scripts\python.exe') -Value 'fixture' -Encoding ASCII
    Set-Content -LiteralPath (Join-Path $gokuRoot 'scripts\knowledge_mcp_v2.py') -Value '# fixture' -Encoding ASCII
    Set-Content -LiteralPath (Join-Path $gokuRoot 'DataIndex\minecraft-knowledge-local\knowledge.test.db') -Value 'fixture' -Encoding ASCII
    Set-Content -LiteralPath (Join-Path $gokuRoot 'DataIndex\minecraft-knowledge-local\_ACTIVE_DB.txt') -Value 'knowledge.test.db' -Encoding ASCII

    $sync = Join-Path $repo 'scripts\Sync-CodexConverterWorkspace.ps1'
    & powershell -NoProfile -ExecutionPolicy Bypass -File $sync -RepoRoot $repo -Workspace $workspace -GokuRoot $gokuRoot -PrepareOnly
    if ($LASTEXITCODE -ne 0) { throw "native workspace synchronization failed with exit $LASTEXITCODE" }
    Assert-True (Test-Path -LiteralPath (Join-Path $workspace 'AGENTS.md')) 'guidance synced'
    Assert-True (Test-Path -LiteralPath (Join-Path $workspace '.agents\skills\legacy-java-converter-vnext\SKILL.md')) 'skill synced'
    Assert-True (Test-Path -LiteralPath (Join-Path $workspace '.codex\config.toml')) 'MCP config synced'
    Assert-True (Test-Path -LiteralPath $sentinel) 'user file preserved'
    Assert-FileDoesNotContain (Join-Path $workspace '.codex\config.toml') '__GOKU_' 'Goku placeholders resolved'
    Assert-FileDoesNotContain (Join-Path $workspace '.codex\config.toml') '__KNOWLEDGE_' 'knowledge placeholders resolved'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $workspace '.grok'))) 'legacy discovery not created'
    $firstHash = Get-TreeHash $workspace
    & powershell -NoProfile -ExecutionPolicy Bypass -File $sync -RepoRoot $repo -Workspace $workspace -GokuRoot $gokuRoot -PrepareOnly
    if ($LASTEXITCODE -ne 0) { throw "second native workspace synchronization failed with exit $LASTEXITCODE" }
    Assert-Equal (Get-TreeHash $workspace) $firstHash 'workspace synchronization is idempotent'

    $compatSync = Join-Path $repo 'scripts\Sync-GokuaiConverterWorkspace.ps1'
    $compatOutput = (& powershell -NoProfile -ExecutionPolicy Bypass -File $compatSync -RepoRoot $repo -Workspace $workspace -GokuRoot $gokuRoot -SkillsOnly -PrepareOnly 3>&1 | Out-String)
    Assert-True ($LASTEXITCODE -eq 0) 'compatibility sync forwards successfully'
    Assert-Contains $compatOutput 'deprecated' 'compatibility sync warns'

    $staleOverlay = Join-Path $fixture 'stale overlay'
    Copy-Item -LiteralPath $overlay -Destination $staleOverlay -Recurse -Force
    Remove-Item -LiteralPath (Join-Path $staleOverlay '.agents\skills\legacy-java-converter-vnext\SKILL.md') -Force
    $savedErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $failureOutput = (& powershell -NoProfile -ExecutionPolicy Bypass -File $sync -RepoRoot $repo -OverlayRoot $staleOverlay -Workspace (Join-Path $fixture 'incomplete workspace') -GokuRoot $gokuRoot -PrepareOnly 2>&1 | Out-String)
        $failureExitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $savedErrorActionPreference
    }
    Assert-True ($failureExitCode -ne 0) 'incomplete native overlay fails closed'
    Assert-Contains $failureOutput '.agents\skills\legacy-java-converter-vnext\SKILL.md' 'missing native file identified'

    $failedOutput = Join-Path $fixture "Mod's Failed Output 26.2"
    New-Item -ItemType Directory -Path $failedOutput -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $failedOutput 'SOURCE_PROFILE.json') -Value '{"minecraftVersion":"1.21.4"}' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $failedOutput 'conversion-manifest.json') -Value '{"target":"26.2"}' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $failedOutput 'MIGRATION_EVIDENCE.md') -Value '# Evidence' -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $failedOutput 'compile-errors.log') -Value 'fixture error' -Encoding UTF8
    $fakeCodex = Join-Path $fixture 'fake codex.exe'
    Set-Content -LiteralPath $fakeCodex -Value 'fixture' -Encoding ASCII
    $launcher = Join-Path $repo 'Open-CodexRepairSession.ps1'
    $launchOutput = (& powershell -NoProfile -ExecutionPolicy Bypass -File $launcher -FailedOutput $failedOutput -GokuRoot $gokuRoot -CodexPath $fakeCodex -PrepareOnly | Out-String)
    Assert-True ($LASTEXITCODE -eq 0) 'native launcher prepare-only succeeds'
    $launchJson = @($launchOutput -split '\r?\n' | Where-Object { $_.TrimStart().StartsWith('{') } | Select-Object -Last 1)[0] | ConvertFrom-Json
    Assert-True ([bool]$launchJson.Ready) 'native launcher reports ready'
    Assert-Equal $launchJson.CodexPath $fakeCodex 'explicit Codex path used'
    $workingIndex = [Array]::IndexOf([object[]]$launchJson.Arguments, '-C')
    Assert-True ($workingIndex -ge 0) 'Codex working-directory argument present'
    Assert-Equal $launchJson.Arguments[$workingIndex + 1] $failedOutput 'failed output path remains one argument'
    Assert-True (Test-Path -LiteralPath (Join-Path $failedOutput 'CODEX_REPAIR_REQUEST.md')) 'launcher writes native request'
    Assert-True (-not (($launchJson.Arguments -join ' ') -match 'grok-home|GROK_HOME|grok mcp')) 'launcher arguments contain no Grok runtime dependency'

    $mainForm = Get-Content -LiteralPath (Join-Path $repo 'src\RB.LegacyJavaConverter\MainForm.cs') -Raw
    Assert-Contains $mainForm 'Repair with GokuCodexAI' 'GUI uses native repair label'
    Assert-Contains $mainForm 'LaunchCodexRepairSession' 'GUI uses native repair method'
    Assert-NotContains $mainForm '"Fix in Grok"' 'GUI removes legacy repair label'
    $converterScript = Get-Content -LiteralPath (Join-Path $repo 'Convert-Forge1201-ToNeoForge262.ps1') -Raw
    Assert-Contains $converterScript 'Write-CodexRepairRequest' 'compile failure writes native request'
    $compatLauncher = Get-Content -LiteralPath (Join-Path $repo 'Open-GrokRepairSession.ps1') -Raw
    Assert-Contains $compatLauncher 'Open-CodexRepairSession.ps1' 'legacy launcher forwards to native launcher'
    Assert-NotContains $compatLauncher 'grok.exe' 'legacy launcher contains no Grok executable dependency'
    Assert-NotContains $compatLauncher 'GROK_HOME' 'legacy launcher contains no Grok environment dependency'
}
finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}

Write-Host "Codex handoff tests passed: $script:passed" -ForegroundColor Green
