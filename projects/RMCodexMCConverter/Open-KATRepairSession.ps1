[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$ProjectPath,
    [string]$Root='C:\GokuCodexAI',
    [Parameter(Mandatory=$true)][string]$PromptFile,
    [int]$Port=8888
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$failed=(Resolve-Path -LiteralPath (Split-Path -Parent $PromptFile)).Path
$workspace=(Resolve-Path -LiteralPath $ProjectPath).Path
$gradleHome=Join-Path $env:USERPROFILE '.gradle'
if(-not(Test-Path -LiteralPath $gradleHome -PathType Container)){throw 'Gradle user cache missing'}
$env:GRADLE_USER_HOME=$gradleHome
if(-not(Test-Path -LiteralPath $PromptFile -PathType Leaf)){throw "Repair request missing: $PromptFile"}
$triage=Join-Path $PSScriptRoot 'Prepare-RepairTriage.ps1'
if(Test-Path -LiteralPath $triage -PathType Leaf){ & powershell -NoProfile -ExecutionPolicy Bypass -File $triage -ProjectRoot $failed }

try{$health=Invoke-RestMethod -Uri "http://127.0.0.1:$Port/health" -TimeoutSec 3}catch{$health=$null}
if(-not $health -or $health.status -ne 'ok'){
    $backend=Join-Path $Root 'Start-GokuBackend.ps1'
    if(-not(Test-Path -LiteralPath $backend -PathType Leaf)){throw "KAT backend is offline and starter is missing: $backend"}
    & $backend -Port $Port
    Start-Sleep -Seconds 2
    $health=Invoke-RestMethod -Uri "http://127.0.0.1:$Port/health" -TimeoutSec 10
    if($health.status -ne 'ok'){throw "KAT backend did not become healthy on port $Port"}
}

$codexCommand=Get-Command codex -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
$codex=if($codexCommand){$codexCommand.Source}else{$null}
if(-not $codex){
    $savedErrorActionPreference=$ErrorActionPreference
    try{$ErrorActionPreference='SilentlyContinue';$codex=where.exe codex.exe 2>$null | Where-Object {Test-Path -LiteralPath $_ -PathType Leaf} | Select-Object -First 1}
    finally{$ErrorActionPreference=$savedErrorActionPreference}
}
if(-not $codex){
    $knownPackages=@(
        'C:\Program Files\WindowsApps\OpenAI.CodexBeta_26.727.4816.0_x64__2p2nqsd0c76g0\app\resources\codex.exe',
        'C:\Program Files\WindowsApps\OpenAI.CodexBeta_*\app\resources\codex.exe',
        'C:\Program Files\WindowsApps\OpenAI.Codex_*\app\resources\codex.exe'
    )
    foreach($pattern in $knownPackages){$match=Resolve-Path -Path $pattern -ErrorAction SilentlyContinue | Sort-Object Path -Descending | Select-Object -First 1;if($match){$codex=$match.Path;break}}
}
if(-not $codex){throw 'Codex CLI host could not be located. This host supplies tools only; the model remains local KAT.'}

$guidance=Join-Path $failed 'CODEX_GUIDANCE.md'
$activeGuidance=Join-Path $failed 'ACTIVE_CODEX_GUIDANCE.md'
$hasGuidance=Test-Path -LiteralPath $guidance -PathType Leaf
if($hasGuidance){
    if(Test-Path -LiteralPath $activeGuidance -PathType Leaf){
        $archive=Join-Path $failed ("CODEX_GUIDANCE_APPLIED_{0}.md" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
        Move-Item -LiteralPath $activeGuidance -Destination $archive -Force
    }
    Move-Item -LiteralPath $guidance -Destination $activeGuidance -Force
    $handoffLock=Join-Path $failed 'CODEX_TO_KAT_HANDOFF.lock'
    if(Test-Path -LiteralPath $handoffLock -PathType Leaf){Remove-Item -LiteralPath $handoffLock -Force}
}
$prompt=if($hasGuidance){"APPLY CODEX GUIDANCE ONCE. Read ONLY $activeGuidance and files it names. This generated conversion may not be a Git repository: NEVER run git commands. If an instructed change is already present, accept it and continue without rewriting it. Apply any remaining exact instructions and run one build using C:\GokuCodexAI\projects\RMCodexMCConverter\Build-WithDestinationJava.ps1 -ProjectRoot $failed. If that build exposes one small error caused by applying the guidance, make one grounded correction and run one final build. As soon as a build reaches compiler errors outside this guidance family, write KAT_PASS_RESULT.md and STOP without inspecting or fixing those later errors. Never exceed two builds."}else{"ONE-PASS LOCAL REPAIR. You are KAT running locally through the Codex tool host; no OpenAI model is in use. Read ONLY $failed\ACTIVE_REPAIR_PASS.md, then only the source files named there. This generated conversion may not be a Git repository: NEVER run git commands. NEVER recursively search .gradle, ng_execute, caches, source trees, or directories. NEVER repeat a command that returned no output. For exact Minecraft or NeoForge API evidence, run this resolver ONCE per symbol: powershell -NoProfile -File C:\GokuCodexAI\projects\RMCodexMCConverter\Find-ExactSource.ps1 -ProjectRoot $failed -Symbol <ClassName> -ReadFirst. If one lookup fails, record it; after two empty or failed tool calls, write KAT_PASS_RESULT.md and STOP. Work only on the active family. Make one coherent edit pass, run exactly one build using powershell -NoProfile -File C:\GokuCodexAI\projects\RMCodexMCConverter\Build-WithDestinationJava.ps1 -ProjectRoot $failed, write $failed\KAT_PASS_RESULT.md, and STOP. Do not continue to another family, seek the full picture, or wait for compaction."}
$codexArgs=@('-C',$failed,'--add-dir',$workspace,'--add-dir',$gradleHome,'-s','workspace-write','-a','never','-m','goku-local','-c','model_provider="goku"','-c','model_providers.goku.name="Local KAT"','-c',"model_providers.goku.base_url=`"http://127.0.0.1:$Port/v1`"",'-c','model_providers.goku.wire_api="responses"','-c','model_context_window=196608','-c','model_auto_compact_token_limit=180000',$prompt)
function ConvertTo-PowerShellLiteral([string]$Value){return "'"+$Value.Replace("'","''")+"'"}
$commandParts=@((ConvertTo-PowerShellLiteral $codex));$commandParts+=@($codexArgs|ForEach-Object{ConvertTo-PowerShellLiteral ([string]$_)})
$banner="Write-Host 'LOCAL KAT REPAIR - goku-local on 127.0.0.1:$Port - no OpenAI model usage' -ForegroundColor Green; "
$interactiveCommand=$banner+'& '+($commandParts -join ' ')
$encodedCommand=[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($interactiveCommand))
$process=Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoExit','-NoProfile','-EncodedCommand',$encodedCommand) -WorkingDirectory $failed -PassThru
if(-not $process){throw 'The interactive KAT repair window could not be started.'}
$watcher=Join-Path $PSScriptRoot 'Watch-KATRepairSession.ps1'
if(Test-Path -LiteralPath $watcher){$maxBuilds=if($hasGuidance){2}else{1};Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile','-WindowStyle','Hidden','-File',$watcher,'-TerminalProcessId',$process.Id,'-ProjectRoot',$failed,'-Workspace',$workspace,'-StartedAt',(Get-Date).ToString('o'),'-MaxBuilds',$maxBuilds) -WindowStyle Hidden|Out-Null}
Write-Host "Opened LOCAL KAT repair for $failed (PID $($process.Id)). No OpenAI model was selected." -ForegroundColor Green
