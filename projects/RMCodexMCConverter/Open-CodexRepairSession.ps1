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
$codex=(Get-Command codex -ErrorAction Stop).Source
$prompt="Open and follow the complete repair request at: $PromptFile. The failed conversion is at: $failed. Work only in that failed output. Check hardened fixes and exact-version evidence before editing. Validate with the named destination-Java build command."
$args=@('-C',$failed,'--add-dir',$workspace,'-m','gpt-5.6-sol','-c','model_reasoning_effort="medium"',$prompt)
Start-Process -FilePath $codex -ArgumentList $args -WorkingDirectory $failed
Write-Host "Opened Codex repair session for $failed" -ForegroundColor Green
