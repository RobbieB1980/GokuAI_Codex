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
if(-not(Test-Path -LiteralPath $PromptFile -PathType Leaf)){throw "Repair request missing: $PromptFile"}

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

$prompt="LOCAL-FIRST REPAIR. You are KAT running locally through the Codex tool host; do not claim to be an OpenAI model. Open and follow the complete repair request at: $PromptFile. Repair only: $failed. Read hardened fixes and exact-version evidence before editing. CONTEXT LIMIT: never use Get-Content -Raw on logs, primers, source trees, or files over 200 lines. Use Select-String first, then read at most 120 relevant lines. Never read an entire compile-errors.log or primer. Keep total gathered evidence below 12000 tokens. WINDOWS TOOL RULES: Do not use python, py, Add-Type, GZipFile, or create an extracted mc_sources tree. A .jar is ZIP, not gzip. Inspect exact generated Minecraft sources with: tar.exe -tf <sources.jar> | Select-String <ClassName>; read one entry with: tar.exe -xOf <sources.jar> <entry/path.java>. The source jar is under <failed>\build\moddev\artifacts\minecraft-patched-*-sources.jar after Gradle setup. If a command is missing or access is denied, do not try an equivalent variant; use an existing supported command or escalate. REPAIR BUDGET: group errors by root cause; at most 3 edit/build cycles and 3 builds. If the same root error survives 2 builds or two environment/tool commands fail, stop and write KAT_ESCALATION.md with exact evidence and the unresolved question. Build and iterate. If evidence is conflicting or the repair remains unresolved after bounded attempts, stop and write KAT_ESCALATION.md; do not call an online model."
$codexArgs=@('-C',$failed,'--add-dir',$workspace,'-s','workspace-write','-a','never','-m','goku-local','-c','model_provider="goku"','-c','model_providers.goku.name="Local KAT"','-c',"model_providers.goku.base_url=`"http://127.0.0.1:$Port/v1`"",'-c','model_providers.goku.wire_api="responses"','-c','model_context_window=65536','-c','model_auto_compact_token_limit=48000',$prompt)
function ConvertTo-PowerShellLiteral([string]$Value){return "'"+$Value.Replace("'","''")+"'"}
$commandParts=@((ConvertTo-PowerShellLiteral $codex));$commandParts+=@($codexArgs|ForEach-Object{ConvertTo-PowerShellLiteral ([string]$_)})
$banner="Write-Host 'LOCAL KAT REPAIR - goku-local on 127.0.0.1:$Port - no OpenAI model usage' -ForegroundColor Green; "
$interactiveCommand=$banner+'& '+($commandParts -join ' ')
$encodedCommand=[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($interactiveCommand))
$process=Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoExit','-NoProfile','-EncodedCommand',$encodedCommand) -WorkingDirectory $failed -PassThru
if(-not $process){throw 'The interactive KAT repair window could not be started.'}
Write-Host "Opened LOCAL KAT repair for $failed (PID $($process.Id)). No OpenAI model was selected." -ForegroundColor Green