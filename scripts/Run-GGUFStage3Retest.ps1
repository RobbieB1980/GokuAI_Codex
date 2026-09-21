[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = 'C:\GokuCodexAI'
$runtime = Join-Path $root 'runtime\llama.cpp\llama-server.exe'
$python = 'python'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$runDir = Join-Path $root "benchmarks\gguf-b11057-retest-$stamp"
New-Item -ItemType Directory -Force -Path $runDir | Out-Null

$models = @(
    [pscustomobject]@{ key='huihui-qwen38-27b-abliterated-q4km'; label='Huihui Qwen3.8 27B abliterated UD-DW Q4_K_M'; file='Huihui-Qwen3.8-27B-abliterated-UD-DW-Q4_K_M.gguf'; ctx=32768 },
    [pscustomobject]@{ key='qwen3-coder-30b-a3b-q4_0'; label='Qwen3-Coder 30B A3B Instruct 1M Q4_0'; file='Qwen3-Coder-30B-A3B-Instruct-1M-Q4_0.gguf'; ctx=32768 },
    [pscustomobject]@{ key='kat-reap50-q6k'; label='KAT reap50 Q6_K'; file='kat-reap50-Q6_K.gguf'; ctx=65536 },
    [pscustomobject]@{ key='qwen38-27b-q4km'; label='Qwen3.8 27B Q4_K_M'; file='Qwen3.8-27B-Q4_K_M.gguf'; ctx=32768 }
)

function Stop-RecordedWorker {
    $pidPath = Join-Path $root 'state\llama-server.pid'
    if (Test-Path -LiteralPath $pidPath) {
        $recordedPid = [int](Get-Content -LiteralPath $pidPath -Raw)
        if ($recordedPid -gt 0) { Stop-Process -Id $recordedPid -Force -ErrorAction SilentlyContinue }
    }
    Get-CimInstance Win32_Process | Where-Object {
        $_.Name -eq 'llama-server.exe' -and $_.CommandLine -match [regex]::Escape($root)
    } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    Start-Sleep -Seconds 3
}

function Wait-Health([int]$Port, [int]$Seconds) {
    $deadline = (Get-Date).AddSeconds($Seconds)
    do {
        try {
            $r = Invoke-WebRequest -Uri "http://127.0.0.1:$Port/health" -UseBasicParsing -TimeoutSec 2
            if ($r.StatusCode -eq 200) { return $true }
        } catch { }
        Start-Sleep -Seconds 2
    } while ((Get-Date) -lt $deadline)
    return $false
}

$summary = @()
try {
    foreach ($m in $models) {
        Stop-RecordedWorker
        $stderr = Join-Path $runDir "$($m.key).stderr.log"
        $stdout = Join-Path $runDir "$($m.key).stdout.log"
        $args = @(
            '-m',(Join-Path $root "models\$($m.file)"),'--alias','goku-heavy','--host','127.0.0.1','--port','8888',
            '--ctx-size',"$($m.ctx)",'--gpu-layers','all','--flash-attn','on','--cache-type-k','q8_0','--cache-type-v','q8_0',
            '--parallel','1','--batch-size','2048','--ubatch-size','1024','--threads','16','--jinja','--reasoning','on',
            '--reasoning-effort','medium','--reasoning-budget','384','--reasoning-format','deepseek','--no-reasoning-preserve',
            '--spec-type','ngram-mod','--spec-ngram-mod-n-match','24','--spec-ngram-mod-n-min','48','--spec-ngram-mod-n-max','64',
            '--temp','0.6','--top-k','20','--top-p','0.95','--min-p','0','--presence-penalty','0','--repeat-penalty','1.0'
        )
        $started = Get-Date
        $proc = Start-Process -FilePath $runtime -ArgumentList $args -WorkingDirectory (Split-Path $runtime -Parent) -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
        if (-not (Wait-Health -Port 8888 -Seconds 180)) {
            $summary += [pscustomobject]@{ model=$m.key; startup='failed'; pid=$proc.Id; report=$null; elapsed_seconds=[math]::Round(((Get-Date)-$started).TotalSeconds,2) }
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
            continue
        }
        $startupSeconds = [math]::Round(((Get-Date)-$started).TotalSeconds,2)
        & nvidia-smi --query-compute-apps=pid,used_memory --format=csv,noheader,nounits | Set-Content -LiteralPath (Join-Path $runDir "$($m.key).vram-start.csv") -Encoding ASCII
        $report = Join-Path $runDir "$($m.key).stage3.json"
        & $python (Join-Path $root 'scripts\benchmark_stage3.py') --url 'http://127.0.0.1:8888/v1/chat/completions' --index (Join-Path $root 'DataIndex\goku-data.db') --output $report --report-as $m.key --worker-label $m.label
        $benchExit = $LASTEXITCODE
        & nvidia-smi --query-compute-apps=pid,used_memory --format=csv,noheader,nounits | Set-Content -LiteralPath (Join-Path $runDir "$($m.key).vram-end.csv") -Encoding ASCII
        $summary += [pscustomobject]@{ model=$m.key; startup='ok'; startup_seconds=$startupSeconds; pid=$proc.Id; report=$report; benchmark_exit=$benchExit; elapsed_seconds=[math]::Round(((Get-Date)-$started).TotalSeconds,2) }
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
    }
} finally {
    Stop-RecordedWorker
    & (Join-Path $root 'Start-GokuBackend.ps1') -Profile kat -Port 8888 -ForceRestart
    $katHealthy = Wait-Health -Port 8888 -Seconds 180
    $summary | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $runDir 'run-summary.json') -Encoding UTF8
    [pscustomobject]@{ run_dir=$runDir; kat_restored=$katHealthy; completed=(Get-Date).ToString('o') } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $runDir 'completion.json') -Encoding UTF8
}

Write-Output $runDir
