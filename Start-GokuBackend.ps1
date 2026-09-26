[CmdletBinding()]
param([ValidateSet('kat','qwen38')][string]$Profile = 'kat', [int]$Port = 8888, [switch]$ForceRestart)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot
$config = Get-Content -LiteralPath (Join-Path $repo 'config\gokuai.json') -Raw | ConvertFrom-Json
$worker = if ($Profile -eq 'qwen38') { $config.workers.escalation } else { $config.workers.default }
$model = [pscustomobject]@{ alias=$config.model.alias; model=$worker.model; context_size=$worker.context_size; batch_size=$config.model.batch_size; ubatch_size=$config.model.ubatch_size }
$runtime = $config.runtime
$logDir = Join-Path $repo 'logs'
$stateDir = Join-Path $repo 'state'
New-Item -ItemType Directory -Force -Path $logDir,$stateDir | Out-Null
if (-not (Test-Path -LiteralPath $runtime -PathType Leaf)) { throw "llama-server missing: $runtime" }
if (-not (Test-Path -LiteralPath $model.model -PathType Leaf)) { throw "model missing: $($model.model)" }

$pidPath = Join-Path $stateDir 'llama-server.pid'
if ($ForceRestart -and (Test-Path -LiteralPath $pidPath)) {
    $oldPid = [int](Get-Content -LiteralPath $pidPath -Raw)
    Stop-Process -Id $oldPid -Force -ErrorAction SilentlyContinue
}
try {
    $health = Invoke-WebRequest -Uri "http://127.0.0.1:$Port/health" -UseBasicParsing -TimeoutSec 2
    if ($health.StatusCode -lt 500) {
        $activePath = Join-Path $stateDir 'active-worker.json'
        $active = if (Test-Path $activePath) { Get-Content $activePath -Raw | ConvertFrom-Json } else { $null }
        if ($active -and $active.profile -eq $Profile) {
            Write-Host "Persistent $Profile backend is already healthy on port $Port." -ForegroundColor Green
            return
        }
    }
} catch { }

$args = @(
    '-m',$model.model,'--alias',$model.alias,'--host','127.0.0.1','--port',"$Port",
    '--device','CUDA0','--split-mode','none','--main-gpu','0',
    '--ctx-size',"$($model.context_size)",'--predict','8192','--gpu-layers','all',
    '--n-cpu-moe','0','--n-cpu-ffn','0','--fit','off','--flash-attn','on','--kv-offload',
    '--cache-type-k','q8_0','--cache-type-v','q8_0','--parallel','1',
    '--batch-size',"$($model.batch_size)",'--ubatch-size',"$($model.ubatch_size)",
    '--threads','16','--threads-batch','16','--jinja','--reasoning','on','--reasoning-effort','medium',
    '--reasoning-budget','384','--reasoning-format','deepseek','--no-reasoning-preserve',
    '--spec-type','ngram-mod','--spec-ngram-mod-n-match','24',
    '--spec-ngram-mod-n-min','48','--spec-ngram-mod-n-max','64',
    '--temp','0.2','--top-k','20','--top-p','0.95','--min-p','0.05',
    '--presence-penalty','0','--repeat-penalty','1.0'
)
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$stdout = Join-Path $logDir "llama-kat-$stamp.stdout.log"
$stderr = Join-Path $logDir "llama-kat-$stamp.stderr.log"
$proc = Start-Process -FilePath $runtime -ArgumentList $args -WorkingDirectory (Split-Path $runtime -Parent) `
    -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
$proc.Id | Set-Content -LiteralPath $pidPath -Encoding ASCII
[ordered]@{profile=$Profile;alias=$model.alias;model=$model.model;pid=$proc.Id;port=$Port;gpu_layers='all';cpu_moe_layers=0;reasoning='on';reasoning_budget=384;speculative_decoding='ngram-mod';started=(Get-Date).ToString('o')} |
    ConvertTo-Json | Set-Content -LiteralPath (Join-Path $stateDir 'active-worker.json') -Encoding UTF8
Write-Host "Started persistent $Profile worker (PID $($proc.Id)) on 127.0.0.1:$Port" -ForegroundColor Green
Write-Host 'GPU-only; thinking and ngram-mod enabled.'
Write-Host "Logs: $stderr"
