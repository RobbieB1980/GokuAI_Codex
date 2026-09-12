[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$ProjectPath,
    [string]$Root='C:\GokuCodexAI',
    [Parameter(Mandatory=$true)][string]$PromptFile
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$failed=(Resolve-Path -LiteralPath (Split-Path -Parent $PromptFile)).Path
$workspace=(Resolve-Path -LiteralPath $ProjectPath).Path
if(-not(Test-Path -LiteralPath $PromptFile -PathType Leaf)){throw "Repair request missing: $PromptFile"}

$codexCommand=Get-Command codex -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
$codex=if($codexCommand){$codexCommand.Source}else{$null}
if(-not $codex){
    $savedErrorActionPreference=$ErrorActionPreference
    try{
        $ErrorActionPreference='SilentlyContinue'
        $codex=where.exe codex.exe 2>$null | Where-Object {Test-Path -LiteralPath $_ -PathType Leaf} | Select-Object -First 1
    }
    finally{$ErrorActionPreference=$savedErrorActionPreference}
}
if(-not $codex){
    $knownPackages=@(
        'C:\Program Files\WindowsApps\OpenAI.CodexBeta_26.727.4816.0_x64__2p2nqsd0c76g0\app\resources\codex.exe',
        'C:\Program Files\WindowsApps\OpenAI.CodexBeta_*\app\resources\codex.exe',
        'C:\Program Files\WindowsApps\OpenAI.Codex_*\app\resources\codex.exe'
    )
    foreach($pattern in $knownPackages){
        $match=Resolve-Path -Path $pattern -ErrorAction SilentlyContinue | Sort-Object Path -Descending | Select-Object -First 1
        if($match){$codex=$match.Path;break}
    }
}
if(-not $codex){
    throw 'Codex CLI could not be located. Open the Codex desktop app once, then retry Repair in Codex.'
}

$prompt="CODEX SOL MEDIUM ESCALATION - ANALYSIS ONLY. Read $PromptFile and $failed\ACTIVE_REPAIR_PASS.md. Do not edit Java and do not build. Work out a precise grounded solution for the active pass and write it to $failed\CODEX_GUIDANCE.md with exact files, API changes, evidence paths, and the build command KAT must run. Prefer apply_patch. If apply_patch cannot create CODEX_GUIDANCE.md, you MUST use one PowerShell [IO.File]::WriteAllText call to write that markdown file only; this handoff fallback does not count against the analysis tool-failure limit. Verify that CODEX_GUIDANCE.md exists and is non-empty before stopping."
$codexArgs=@('-C',$failed,'--add-dir',$workspace,'-s','workspace-write','-a','never','-m','gpt-5.6-sol','-c','model_reasoning_effort="medium"',$prompt)
function ConvertTo-PowerShellLiteral([string]$Value){
    return "'" + $Value.Replace("'", "''") + "'"
}
$commandParts=@((ConvertTo-PowerShellLiteral $codex))
$commandParts+=@($codexArgs | ForEach-Object {ConvertTo-PowerShellLiteral ([string]$_)})
$interactiveCommand='& ' + ($commandParts -join ' ')
$encodedCommand=[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($interactiveCommand))
$handoffLock=Join-Path $failed 'CODEX_TO_KAT_HANDOFF.lock'
if(Test-Path -LiteralPath $handoffLock -PathType Leaf){Remove-Item -LiteralPath $handoffLock -Force}
$process=Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoExit','-NoProfile','-EncodedCommand',$encodedCommand) -WorkingDirectory $failed -PassThru
if(-not $process){throw 'The interactive Codex repair window could not be started.'}
$watcher=Join-Path $PSScriptRoot 'Watch-CodexGuidance.ps1'
if(Test-Path -LiteralPath $watcher -PathType Leaf){
    Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-WindowStyle','Hidden','-File',$watcher,'-TerminalProcessId',$process.Id,'-ProjectRoot',$failed,'-Workspace',$workspace,'-PromptFile',$PromptFile,'-StartedAt',(Get-Date).ToString('o')) -WindowStyle Hidden | Out-Null
}
Write-Host "Opened interactive Codex repair window for $failed (PID $($process.Id))" -ForegroundColor Green
