[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = 'C:\GokuCodexAI'
$runtime = Join-Path $root 'runtime\llama.cpp\llama-server.exe'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$runDir = Join-Path $root "benchmarks\qwen25-coder14b-b11057-retest-$stamp"
New-Item -ItemType Directory -Force -Path $runDir | Out-Null

function Stop-LocalServer {
    Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'llama-server.exe' -and $_.CommandLine -match [regex]::Escape($root) } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    Start-Sleep -Seconds 3
}
function Wait-Health([int]$Seconds) {
    $deadline = (Get-Date).AddSeconds($Seconds)
    do {
        try { if ((Invoke-WebRequest 'http://127.0.0.1:8888/health' -UseBasicParsing -TimeoutSec 2).StatusCode -eq 200) { return $true } } catch { }
        Start-Sleep -Seconds 2
    } while ((Get-Date) -lt $deadline)
    return $false
}

$summary = $null
try {
    Stop-LocalServer
    $stderr = Join-Path $runDir 'qwen25-coder-14b-q6kl.stderr.log'
    $stdout = Join-Path $runDir 'qwen25-coder-14b-q6kl.stdout.log'
    $args = @(
        '-m',(Join-Path $root 'models\Qwen2.5-Coder-14B-Instruct-Q6_K_L.gguf'),'--alias','goku-heavy','--host','127.0.0.1','--port','8888',
        '--device','CUDA0','--split-mode','none','--main-gpu','0','--gpu-layers','all','--n-cpu-moe','0','--n-cpu-ffn','0','--fit','off',
        '--ctx-size','32768','--predict','8192','--flash-attn','on','--kv-offload','--cache-type-k','q8_0','--cache-type-v','q8_0',
        '--parallel','1','--batch-size','2048','--ubatch-size','1024','--threads','16','--threads-batch','16','--jinja',
        '--reasoning','on','--reasoning-effort','medium','--reasoning-budget','384','--reasoning-format','deepseek','--no-reasoning-preserve',
        '--spec-type','ngram-mod','--spec-ngram-mod-n-match','24','--spec-ngram-mod-n-min','48','--spec-ngram-mod-n-max','64',
        '--cache-prompt','--temp','0.2','--top-k','20','--top-p','0.95','--min-p','0.05','--repeat-penalty','1.0','--metrics','--no-webui','--cors-origins','localhost'
    )
    $started = Get-Date
    $proc = Start-Process -FilePath $runtime -ArgumentList $args -WorkingDirectory (Split-Path $runtime -Parent) -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
    if (-not (Wait-Health 180)) { throw "Qwen2.5-Coder startup failed; see $stderr" }
    $startupSeconds = [math]::Round(((Get-Date)-$started).TotalSeconds,2)
    $gpuUsed = [int]((& nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits).Trim())
    $report = Join-Path $runDir 'qwen25-coder-14b-q6kl.stage3.json'
    & python (Join-Path $root 'scripts\benchmark_stage3.py') --url 'http://127.0.0.1:8888/v1/chat/completions' --index (Join-Path $root 'DataIndex\goku-data.db') --output $report --report-as 'qwen25-coder-14b-q6kl' --worker-label 'Qwen2.5 Coder 14B Instruct Q6_K_L'
    $summary = [pscustomobject]@{model='qwen25-coder-14b-q6kl';startup='ok';startup_seconds=$startupSeconds;pid=$proc.Id;gpu_used_mib=$gpuUsed;report=$report;benchmark_exit=$LASTEXITCODE;elapsed_seconds=[math]::Round(((Get-Date)-$started).TotalSeconds,2)}
} finally {
    Stop-LocalServer
    & (Join-Path $root 'Start-GokuBackend.ps1') -Profile kat -Port 8888 -ForceRestart
    $restored = Wait-Health 180
    if ($null -ne $summary) { $summary | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $runDir 'run-summary.json') -Encoding UTF8 }
    [pscustomobject]@{run_dir=$runDir;kat_restored=$restored;completed=(Get-Date).ToString('o')} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $runDir 'completion.json') -Encoding UTF8
}

Write-Output $runDir
