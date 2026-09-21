# GGUF b11057 retest — ranked recommendation

Runtime: llama.cpp build 11057, commit `59657a613`.

All runs used one model at a time, `--gpu-layers all`, no CPU/MoE offload option, 1 slot, Q8 KV cache, flash attention, and native `ngram-mod` speculation. The benchmark queried `C:\GokuCodexAI\DataIndex\goku-data.db`. KAT was restored on port 8888 after testing.

## Hard acceptance decision

No candidate passes the required knowledge-grounding gate in this run.

The shared stage-3 retriever achieved 94% keyword recall, but did not enforce the required evidence order: zero of 12 packets contained a `Solved_Problems/` hardened-fix path, and only 7 of 12 contained an exact 26.2 path. Consequently, model scores are useful for relative comparison but cannot authorize a routing/default change. Exact-path citation adherence was also incomplete for every model.

## Results

| Rank | Model | Production | Oracle | Mean latency (prod/oracle) | Completion tok/s | Exact citation score | JSON valid | Truncated | Approx. GPU allocation* |
|---:|---|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | KAT reap50 Q6_K | 79.69 | 74.39 | 11.45 / 11.38 s | 150.17 | 58.33 | 11/12 | 1/12 | 15,651 MiB |
| 2 | Qwen3-Coder 30B A3B Q4_0 | 76.26 | 75.90 | 4.49 / 3.98 s | 176.16 | 29.72 | 12/12 | 0/12 | 18,680 MiB |
| 3 | Huihui Qwen3.8 27B abliterated Q4_K_M | 67.08 | 69.42 | 51.49 / 47.31 s | 43.08 | 50.00 | 6/12 | 6/12 | 16,750 MiB |
| 4 | Qwen3.8 27B Q4_K_M | 67.12 | 67.06 | 51.41 / 48.76 s | 40.89 | 50.00 | 6/12 | 6/12 | 17,839 MiB |

\* WDDM did not expose per-process VRAM, so allocation is the total GPU-memory increase over the same 1,054 MiB idle baseline. All four fit on the 24 GiB RTX 4090 without OOM.

Retrieval recall was 94% for every model because retrieval is performed by the harness. “Exact citation score” is the mean percentage of returned citation strings that exactly matched supplied passage paths; invalid/truncated JSON scores zero.

## Repair behavior

- KAT had the strongest production result and exact-path citation record (38 valid citations), with one mapping-oracle truncation. It scored 100 repair points on both registry cases and maintained the best overall production score.
- Qwen3-Coder was the speed leader and never truncated. It produced strict JSON in all 12 cases and scored 100 repair points on both registry cases, but often omitted or altered exact evidence paths (20 valid citations; 29.72 mean citation score). It also used the most VRAM.
- Huihui was strong on Gradle and data-components cases and modestly outperformed stock Qwen3.8 overall, but six responses hit the 2,200-token cap, including both registry cases. Those truncations broke JSON and erased citation credit.
- Stock Qwen3.8 showed the same verbosity/truncation failure class as Huihui: six capped responses and six invalid JSON responses.

## Runtime and warning behavior

- All four models started successfully and completed 12/12 requests with no HTTP failures or OOMs.
- Startup time: KAT 6.54 s, stock Qwen3.8 8.54 s, Qwen3-Coder 12.58 s, Huihui 12.59 s.
- b11057 logged active `ngram-mod` draft acceptance during inference for every model.
- Huihui and stock Qwen3.8 emitted warnings that layer-64/`nextn` tensors were unused and ignored. KAT and Qwen3-Coder did not emit those tensor warnings.
- The server also warns that no API key is configured and CORS allows all origins; this is a local-service exposure warning, not a benchmark failure.

## Comparison with Huihui b10917 baseline

Against `newmodel-huihui-stage3-20260920-105928.json`, b11057 Huihui moved from 64.78 to 67.08 production (+2.30) and 69.25 to 69.42 oracle (+0.17). Mean production latency increased from 48.09 to 51.49 seconds; oracle increased from 46.70 to 47.31 seconds. Retrieval stayed at 94%. This is a small quality improvement, not a decisive promotion result.

## Recommendation

1. Keep KAT as the default worker. It remains the best grounded production performer and is substantially faster than either dense Qwen3.8 model.
2. Do not change the configured Qwen3.8 escalation role yet. Qwen3-Coder is the strongest challenger on speed and structured output, but it fails the exact-citation gate and has the largest VRAM footprint.
3. Fix the retrieval harness first: explicitly search `Solved_Problems`, then compact exact-version primers, then exact NeoForge 26.2 sources, and reject packets lacking supplied exact paths. Rerun KAT and Qwen3-Coder after that correction.
4. If dense Qwen3.8 models are retested, enforce a shorter answer contract or higher completion ceiling with valid-JSON recovery; current 50% truncation makes both unsuitable for this bounded converter-repair role.

No default or escalation configuration was modified.
