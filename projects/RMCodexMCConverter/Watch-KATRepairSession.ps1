[CmdletBinding()]
param([Parameter(Mandatory)][int]$TerminalProcessId,[Parameter(Mandatory)][string]$ProjectRoot,[Parameter(Mandatory)][string]$Workspace,[Parameter(Mandatory)][datetime]$StartedAt,[int]$MaxMinutes=8,[int]$MaxToolCalls=20,[int]$MaxBuilds=1)
$ErrorActionPreference='SilentlyContinue'
function Stop-Repair([string]$Reason){
  $path=Join-Path $ProjectRoot 'KAT_WATCHDOG_STOP.md'
 $escalation=Join-Path $ProjectRoot 'KAT_ESCALATION.md'
 $compileLog=Join-Path $ProjectRoot 'compile-errors.log'
 $guidedPassCompleted=$MaxBuilds -gt 1 -and (Test-Path -LiteralPath $compileLog -PathType Leaf) -and [bool](Select-String -LiteralPath $compileLog -Pattern ':\d+: error:' -Quiet)
 if($guidedPassCompleted){
  $result=Join-Path $ProjectRoot 'KAT_PASS_RESULT.md'
  $resultBody="# KAT guided pass result`r`n`r`n- Time: $(Get-Date -Format o)`r`n- Result: The guided family was applied; the validation build advanced to a different compiler-error family.`r`n- Transition reason: $Reason`r`n- Next action: Regroup compile-errors.log and start one bounded local KAT pass.`r`n"
  [IO.File]::WriteAllText($result,$resultBody,(New-Object Text.UTF8Encoding $false))
  & taskkill.exe /PID $TerminalProcessId /T /F 2>$null|Out-Null
  $katLauncher='C:\GokuCodexAI\Open-KATRepairSession.ps1'
  $repairRequest=Join-Path $ProjectRoot 'CODEX_REPAIR_REQUEST.md'
  if((Test-Path $katLauncher) -and (Test-Path $repairRequest)){Start-Process powershell.exe -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$katLauncher,'-ProjectPath',$Workspace,'-PromptFile',$repairRequest) -WorkingDirectory $ProjectRoot|Out-Null}
  exit
 }
 $message="# KAT escalation`r`n`r`nI cannot fix this - escalate to Codex Sol Medium.`r`n`r`n- Watchdog reason: $Reason`r`n- Active pass: $ProjectRoot\ACTIVE_REPAIR_PASS.md`r`n- Codex must analyze only and write CODEX_GUIDANCE.md.`r`n"
 [IO.File]::WriteAllText($escalation,$message,(New-Object Text.UTF8Encoding $false))
 $body="# KAT watchdog stop`r`n`r`n- Time: $(Get-Date -Format o)`r`n- Reason: $Reason`r`n- The repair process was stopped before further unbounded work.`r`n"
 [IO.File]::WriteAllText($path,$body,(New-Object Text.UTF8Encoding $false))
 & taskkill.exe /PID $TerminalProcessId /T /F 2>$null|Out-Null
 if(-not(Test-Path (Join-Path $ProjectRoot 'CODEX_GUIDANCE.md'))){
  $launcher='C:\GokuCodexAI\Open-CodexRepairSession.ps1'
  if(Test-Path $launcher){Start-Process powershell.exe -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$launcher,'-ProjectPath',$Workspace,'-PromptFile',$escalation) -WorkingDirectory $ProjectRoot|Out-Null}
 }
 exit
}
$session=$null
while((Get-Date)-$StartedAt -lt [timespan]::FromMinutes($MaxMinutes)){
 if(-not(Get-Process -Id $TerminalProcessId -ErrorAction SilentlyContinue)){exit}
 if(-not $session){
  $dir=Join-Path $env:USERPROFILE '.codex\sessions'
  $dir=Join-Path $dir (Get-Date -Format 'yyyy')
  $dir=Join-Path $dir (Get-Date -Format 'MM')
  $dir=Join-Path $dir (Get-Date -Format 'dd')
  $session=Get-ChildItem $dir -Filter '*.jsonl' -ErrorAction SilentlyContinue|Where-Object{$_.CreationTime -ge $StartedAt.AddSeconds(-10)}|Sort-Object CreationTime -Descending|Select-Object -First 1
  Start-Sleep -Seconds 2;continue
 }
 $events=@(Get-Content $session.FullName -Tail 240|ForEach-Object{try{$_|ConvertFrom-Json}catch{}})
 $calls=@($events|Where-Object{$_.type -eq 'response_item' -and $_.payload.type -eq 'function_call'})
 if($calls.Count -gt $MaxToolCalls){Stop-Repair "Tool-call budget exceeded ($($calls.Count) > $MaxToolCalls)."}
 $resolverCalls=@($calls|Where-Object{$_.payload.arguments -match 'Find-ExactSource\.ps1'})
 if($resolverCalls.Count -gt 8){Stop-Repair "Exact-source lookup budget exceeded ($($resolverCalls.Count) > 8)."}
 if($calls|Where-Object{$_.payload.arguments -match '(?i)C:\\tmp\\[^"'']+\.ps1|\$script\s*=\s*@'}){Stop-Repair 'Invented temporary script detected.'}
 if($MaxBuilds -le 1 -and $calls.Count -ge 12){
  $edited=Get-ChildItem (Join-Path $ProjectRoot 'src') -Recurse -File -ErrorAction SilentlyContinue|Where-Object{$_.LastWriteTime -gt $StartedAt}|Select-Object -First 1
  if(-not $edited){Stop-Repair 'Twelve tool calls completed without any source edit.'}
 }
 $commands=@($calls|ForEach-Object{try{($_.payload.arguments|ConvertFrom-Json).command}catch{''}}|Where-Object{$_})
 if($commands|Where-Object{$_ -match '(?is)Get-ChildItem.+-Recurse.+(\.gradle|ng_execute|\\caches\\|\\src\\)'}){Stop-Repair 'Forbidden recursive cache/source-tree search detected.'}
 $buildAttempts=@($commands|Where-Object{$_ -match "(?im)^\s*(?:&\s*)?['`"]?[^\r\n]*Build-WithDestinationJava\.ps1(?:['`"]|\s)"})
 if($buildAttempts.Count -gt $MaxBuilds){Stop-Repair "Validation-build budget exceeded ($($buildAttempts.Count) > $MaxBuilds)."}
 if($commands.Count -ge 3){$last=@($commands|Select-Object -Last 3|ForEach-Object{($_ -replace '\s+',' ').Trim()});if($last[0] -eq $last[1] -and $last[1] -eq $last[2]){Stop-Repair 'The same command was attempted three consecutive times.'}}
 $outputs=@($events|Where-Object{$_.type -eq 'response_item' -and $_.payload.type -eq 'function_call_output'}|Select-Object -Last 3)
 if($outputs.Count -eq 3 -and @($outputs|Where-Object{$_.payload.output -match '(?i)\(no output\)|Exit code: [1-9]|access.+denied|not recognized|cannot find path'}).Count -eq 3){Stop-Repair 'Three consecutive empty or failed tool results were detected.'}
 Start-Sleep -Seconds 2
}
Stop-Repair "Wall-clock limit of $MaxMinutes minutes reached."

