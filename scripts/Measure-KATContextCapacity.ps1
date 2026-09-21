[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = 'C:\GokuCodexAI'
$runtime = Join-Path $root 'runtime\llama.cpp\llama-server.exe'
$model = Join-Path $root 'models\kat-reap50-Q6_K.gguf'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$runDir = Join-Path $root "benchmarks\kat-context-capacity-$stamp"
New-Item -ItemType Directory -Force -Path $runDir | Out-Null

function Stop-LocalServer {
    Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'llama-server.exe' -and $_.CommandLine -match [regex]::Escape($root) } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    Start-Sleep -Seconds 4
}
function Wait-Health([int]$Seconds) {
    $deadline = (Get-Date).AddSeconds($Seconds)
    do {
        try { if ((Invoke-WebRequest 'http://127.0.0.1:8888/health' -UseBasicParsing -TimeoutSec 2).StatusCode -eq 200) { return $true } } catch { }
        Start-Sleep -Seconds 2
    } while ((Get-Date) -lt $deadline)
    return $false
}
function Gpu-Used { return [int]((& nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits).Trim()) }

$rows = @()
try {
    Stop-LocalServer
    $idle = Gpu-Used
    foreach ($ctx in @(98304,131072,163840,196608,229376,262144)) {
        $stderr = Join-Path $runDir "kat-ctx-$ctx.stderr.log"
        $stdout = Join-Path $runDir "kat-ctx-$ctx.stdout.log"
        $args = @(
            '-m',$model,'--alias','kat-context-probe','--host','127.0.0.1','--port','8888',
            '--device','CUDA0','--split-mode','none','--main-gpu','0','--gpu-layers','all','--n-cpu-moe','0','--n-cpu-ffn','0','--fit','off',
            '--ctx-size',"$ctx",'--predict','8192','--flash-attn','on','--kv-offload','--cache-type-k','q8_0','--cache-type-v','q8_0',
            '--parallel','1','--batch-size','2048','--ubatch-size','1024','--threads','16','--threads-batch','16','--jinja',
            '--reasoning','on','--reasoning-effort','medium','--reasoning-budget','384','--reasoning-format','deepseek','--no-reasoning-preserve',
            '--spec-type','ngram-mod','--spec-ngram-mod-n-match','24','--spec-ngram-mod-n-min','48','--spec-ngram-mod-n-max','64','--temp','0.2','--top-k','20','--top-p','0.95','--min-p','0.05'
        )
        $started = Get-Date
        $proc = Start-Process -FilePath $runtime -ArgumentList $args -WorkingDirectory (Split-Path $runtime -Parent) -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
        if (-not (Wait-Health 120)) {
            $rows += [pscustomobject]@{context=$ctx;startup='failed';pid=$proc.Id;stderr=$stderr}
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
            break
        }
        $used = Gpu-Used
        $body = @{model='kat-context-probe';messages=@(@{role='user';content='Return exactly: KAT_CONTEXT_OK'});temperature=0;max_tokens=32} | ConvertTo-Json -Depth 5
        $sw = [Diagnostics.Stopwatch]::StartNew()
        try {
            $response = Invoke-RestMethod 'http://127.0.0.1:8888/v1/chat/completions' -Method Post -ContentType 'application/json' -Body $body -TimeoutSec 120
            $inference = 'ok'
            $completionTokens = $response.usage.completion_tokens
        } catch {
            $inference = 'failed: ' + $_.Exception.Message
            $completionTokens = $null
        }
        $sw.Stop()
        $rows += [pscustomobject]@{context=$ctx;startup='ok';startup_seconds=[math]::Round(((Get-Date)-$started).TotalSeconds,2);pid=$proc.Id;gpu_used_mib=$used;allocation_over_idle_mib=$used-$idle;free_mib=24564-$used;inference=$inference;inference_seconds=[math]::Round($sw.Elapsed.TotalSeconds,3);completion_tokens=$completionTokens;stderr=$stderr}
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 4
        if ($used -ge 23000 -or $inference -ne 'ok') { break }
    }
} finally {
    Stop-LocalServer
    & (Join-Path $root 'Start-GokuBackend.ps1') -Profile kat -Port 8888 -ForceRestart
    $restored = Wait-Health 180
    [pscustomobject]@{idle_gpu_used_mib=$idle;gpu_total_mib=24564;rows=$rows;kat_restored=$restored;completed=(Get-Date).ToString('o')} |
        ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $runDir 'capacity-results.json') -Encoding UTF8
}

Write-Output $runDir
