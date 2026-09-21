[CmdletBinding()]
param(
    [Parameter(Mandatory)][int]$TerminalProcessId,
    [Parameter(Mandatory)][string]$ProjectRoot,
    [Parameter(Mandatory)][string]$Workspace,
    [Parameter(Mandatory)][string]$PromptFile,
    [Parameter(Mandatory)][datetime]$StartedAt,
    [int]$MaxMinutes = 30
)

$ErrorActionPreference = 'SilentlyContinue'
$guidance = Join-Path $ProjectRoot 'CODEX_GUIDANCE.md'
$handoffLock = Join-Path $ProjectRoot 'CODEX_TO_KAT_HANDOFF.lock'
$katLauncher = 'C:\GokuCodexAI\Open-KATRepairSession.ps1'
$deadline = $StartedAt.AddMinutes($MaxMinutes)

while ((Get-Date) -lt $deadline) {
    if (Test-Path -LiteralPath $guidance -PathType Leaf) {
        $item = Get-Item -LiteralPath $guidance
        if ($item.LastWriteTime -ge $StartedAt.AddSeconds(-2)) {
            $lockStream = $null
            try {
                $lockStream = [IO.File]::Open($handoffLock, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
                $lockBytes = [Text.Encoding]::UTF8.GetBytes("Claimed $(Get-Date -Format o) by watcher PID $PID")
                $lockStream.Write($lockBytes, 0, $lockBytes.Length)
            }
            catch { exit }
            finally { if ($lockStream) { $lockStream.Dispose() } }
            if (Test-Path -LiteralPath $katLauncher -PathType Leaf) {
                Start-Process -FilePath 'powershell.exe' `
                    -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$katLauncher,'-ProjectPath',$Workspace,'-PromptFile',$PromptFile) `
                    -WorkingDirectory $ProjectRoot | Out-Null
                $marker = Join-Path $ProjectRoot 'CODEX_TO_KAT_HANDOFF.md'
                $body = "# Codex to KAT handoff`r`n`r`n- Time: $(Get-Date -Format o)`r`n- Guidance: $guidance`r`n- KAT was restarted automatically.`r`n"
                [IO.File]::WriteAllText($marker, $body, [Text.UTF8Encoding]::new($false))
            }
            exit
        }
    }
    if (-not (Get-Process -Id $TerminalProcessId -ErrorAction SilentlyContinue)) { exit }
    Start-Sleep -Seconds 2
}
