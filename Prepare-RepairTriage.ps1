[CmdletBinding()]
param([Parameter(Mandatory)][string]$ProjectRoot)
$ErrorActionPreference='Stop'
$log=Join-Path $ProjectRoot 'compile-errors.log'
if(-not(Test-Path -LiteralPath $log -PathType Leaf)){return}
$lines=@(Get-Content -LiteralPath $log);$section=@();$started=$false
foreach($line in $lines){if(-not $started -and $line -match '^> Task :compileJava FAILED'){$started=$true};if($started){$section+=$line};if($started -and $line -match '^\d+ errors?$'){break}}
if(-not $section){$section=$lines}
$errors=@($section|ForEach-Object{$m=[regex]::Match($_,'^(?<file>.+\.java):(?<line>\d+): error: (?<message>.+)$');if($m.Success){[pscustomobject]@{File=$m.Groups['file'].Value;Line=[int]$m.Groups['line'].Value;Message=$m.Groups['message'].Value}}})
$rules=@(
@{Name='Entity models and renderers';Pattern='CowModel|PigModel|RenderType|RenderState|renderToBuffer|registerEntityRenderer|EntityRenderer|renderer'},
@{Name='Block, item and entity registration';Pattern='registerBlock|registerItem|DeferredRegister|PickaxeItem|register\('},
@{Name='Optional values and procedure arithmetic';Pattern='Optional<|bad operand types for binary operator'},
@{Name='GUI, overlay and shader APIs';Pattern='CoreShaders|GuiGraphics|drawString|extractRenderState|Screen|Overlay'},
@{Name='Networking and saved variables';Pattern='Factory|StreamCodec|Payload|SavedData|ModVariables|network'},
@{Name='Biome and world-generation APIs';Pattern='Biome|NoiseGeneratorSettings|HolderGetter|worldgen'},
@{Name='Portal and dimension travel APIs';Pattern='BlockUtil|FoundRectangle|DimensionTransition|PostDimensionTransition|PortalBlock|Teleporter|portal'},
@{Name='Other compiler errors';Pattern='.*'})
$used=New-Object 'System.Collections.Generic.HashSet[int]';$groups=@();$order=0
foreach($rule in $rules){$order++;$items=@();for($i=0;$i -lt $errors.Count;$i++){if($used.Contains($i)){continue};$e=$errors[$i];if("$($e.File) $($e.Message)" -match $rule.Pattern){$items+=$e;$null=$used.Add($i)}};if($items){$groups+=[pscustomobject]@{Order=$order;Name=$rule.Name;ErrorCount=$items.Count;FileCount=@($items.File|Sort-Object -Unique).Count;Examples=@($items|Select-Object -First 5)}}}
$warnings=@($section|Where-Object{$_ -match '^.+\.java:\d+: warning:'}).Count;$capped=($section[-1] -match '^100 errors$')
$report=[pscustomobject]@{SchemaVersion=2;SourceLog=$log;CompilerErrorCount=$errors.Count;WarningCount=$warnings;AffectedFileCount=@($errors.File|Sort-Object -Unique).Count;CompilerOutputMayBeCapped=$capped;Groups=$groups}
$utf8=New-Object System.Text.UTF8Encoding $false;[IO.File]::WriteAllText((Join-Path $ProjectRoot 'REPAIR_PLAN.json'),($report|ConvertTo-Json -Depth 8)+"`r`n",$utf8)
$md=@('# Repair plan','','Generated from the first authoritative `compileJava` section; repeated Gradle exception output is excluded.','',"- Compiler errors shown: $($errors.Count)$(if($capped){' (compiler cap reached; more may remain)'})","- Affected Java files: $(@($errors.File|Sort-Object -Unique).Count)","- Warnings: $warnings (not initial blockers)",'','## Ordered repair passes','')
foreach($g in $groups){$md+="### Pass $($g.Order): $($g.Name)",'',"$($g.ErrorCount) errors across $($g.FileCount) files. Representative diagnostics:",'';foreach($e in $g.Examples){$md+="- ``$($e.File):$($e.Line)`` - $($e.Message)"};$md+=''}
$md+='Repair one pass at a time. After each pass, build once and regenerate this plan. Do not create one request per compiler line.';[IO.File]::WriteAllText((Join-Path $ProjectRoot 'REPAIR_PLAN.md'),(($md-join "`r`n")+"`r`n"),$utf8)
$active=$groups|Select-Object -First 1
if($active){
 $pass=@('# Active repair pass','','This file is the entire repair scope for the next KAT session. Do not read the full compile log or work on later passes.','',"## Pass $($active.Order): $($active.Name)",'',"$($active.ErrorCount) errors across $($active.FileCount) files.",'','Representative diagnostics:','')
 foreach($e in $active.Examples){$pass+="- ``$($e.File):$($e.Line)`` - $($e.Message)"}
 $pass+='','## Session contract','','- Work only on this error family.','- Read only the listed files and narrowly targeted exact-version evidence.','- Never recursively search .gradle, ng_execute, caches, source trees, or directories.','- Never repeat a command that returned no output; after two tool failures, record the blocker and stop.','- Use Find-ExactSource.ps1 once per required symbol for exact API evidence.','- Make one coherent edit pass.','- Run exactly one destination-Java build.','- Write `KAT_PASS_RESULT.md` with files changed, build result, and remaining first error.','- Then stop. Do not continue to another family and do not wait for context compaction.'
 [IO.File]::WriteAllText((Join-Path $ProjectRoot 'ACTIVE_REPAIR_PASS.md'),(($pass-join "`r`n")+"`r`n"),$utf8)
}
Write-Host "Prepared grouped repair plan: $(Join-Path $ProjectRoot 'REPAIR_PLAN.md')"
