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

$prompt="Open and follow the complete repair request at: $PromptFile. The failed conversion is at: $failed. Work only in that failed output. Check hardened fixes and exact-version evidence before editing. Validate with the named destination-Java build command."
$codexArgs=@('-C',$failed,'--add-dir',$workspace,'-m','gpt-5.6-sol','-c','model_reasoning_effort="medium"',$prompt)
function ConvertTo-PowerShellLiteral([string]$Value){
    return "'" + $Value.Replace("'", "''") + "'"
}
$commandParts=@((ConvertTo-PowerShellLiteral $codex))
$commandParts+=@($codexArgs | ForEach-Object {ConvertTo-PowerShellLiteral ([string]$_)})
$interactiveCommand='& ' + ($commandParts -join ' ')
$encodedCommand=[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($interactiveCommand))
$process=Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoExit','-NoProfile','-EncodedCommand',$encodedCommand) -WorkingDirectory $failed -PassThru
if(-not $process){throw 'The interactive Codex repair window could not be started.'}
Write-Host "Opened interactive Codex repair window for $failed (PID $($process.Id))" -ForegroundColor Green