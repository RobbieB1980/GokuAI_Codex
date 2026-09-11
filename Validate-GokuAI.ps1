[CmdletBinding()] param()
Set-StrictMode -Version Latest
$ErrorActionPreference='Continue'; $failures=0
function Check([string]$Label,[string]$Path){if(Test-Path -LiteralPath $Path){Write-Host "[OK] $Label" -ForegroundColor Green}else{Write-Host "[FAIL] ${Label}: $Path" -ForegroundColor Red;$script:failures++}}
$configPath=Join-Path $PSScriptRoot 'config\gokuai.json'; Check 'configuration' $configPath
try{$config=Get-Content -LiteralPath $configPath -Raw|ConvertFrom-Json}catch{Write-Host "[FAIL] invalid JSON: $_" -ForegroundColor Red;exit 1}
Check 'llama.cpp runtime' $config.runtime; Check 'sole KAT model' $config.model.model
Check 'knowledge root' $config.knowledge.root; Check 'hardened fixes' $config.knowledge.hardened_fixes; Check 'active index pointer' $config.knowledge.active_index_pointer
$help=& $config.runtime --help 2>&1|Out-String
if($help-match'ngram-mod'){Write-Host '[OK] llama.cpp supports ngram-mod' -ForegroundColor Green}else{Write-Host '[FAIL] ngram-mod unavailable' -ForegroundColor Red;$failures++}
$start=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Start-GokuBackend.ps1') -Raw
foreach($rule in @(@('GPU-only','--gpu-layers.+all'),@('no CPU MoE','^(?![\s\S]*--n-cpu-moe)'),@('thinking','--reasoning.+on'),@('ngram recipe','--spec-type.+ngram-mod'))){if($start-match$rule[1]){Write-Host "[OK] $($rule[0])" -ForegroundColor Green}else{Write-Host "[FAIL] $($rule[0])" -ForegroundColor Red;$failures++}}
if($config.modes.fast.model_alias-ne$config.modes.code.model_alias){Write-Host '[FAIL] modes do not share one model' -ForegroundColor Red;$failures++}else{Write-Host '[OK] fast/code share persistent KAT' -ForegroundColor Green}
if($failures){Write-Host "Validation failed: $failures" -ForegroundColor Red;exit 1};Write-Host 'Single-model GokuAI validation passed.' -ForegroundColor Green
