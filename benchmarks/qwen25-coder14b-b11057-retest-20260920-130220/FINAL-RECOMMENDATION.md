# Qwen2.5-Coder 14B Q6_K_L — b11057 retest

The model completed all 12 stage-3 requests at 32K context with all layers on CUDA0, Q8 K/V cache, medium reasoning capped at 384 tokens, and `ngram-mod`. KAT was restored afterward.

| Model | Production | Oracle | Mean latency (prod/oracle) | Completion tok/s | Citation score | JSON valid | Truncated | Approx. allocation* |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Qwen2.5-Coder 14B Q6_K_L | 71.72 | 74.30 | 11.38 / 7.74 s | 63.34 | 27.08 | 11/12 | 0/12 | 15,559 MiB |
| KAT reference | 79.69 | 74.39 | 11.45 / 11.38 s | 150.17 | 58.33 | 11/12 | 1/12 | 15,651 MiB |
| EVE 27B reference | 88.28 | 80.38 | 32.87 / 32.85 s | 44.99 | 79.17 | 10/12 | 0/12 | 17,750 MiB |

\* Total GPU use minus the measured 1,054 MiB idle baseline.

## Findings

- Qwen2.5-Coder nearly matched KAT's oracle score but trailed KAT by 7.97 production points and 31.25 citation-score points.
- It generated at only 63.34 completion tokens/sec versus KAT's 150.17 despite using essentially the same VRAM.
- Its low request latency came mainly from much shorter answers, not higher decode throughput.
- Registry and Gradle repair keyword criteria were strong, but exact supplied-path citation adherence was zero for those cases. GeckoLib repair was also weak at 56.25 repair points in both modes.
- It completed 12/12 requests without OOM, request failure, or truncation. Eleven responses were valid strict JSON.
- llama.cpp warned that the GGUF's `</s>` token was not typed as a control token and overrode it, indicating tokenizer metadata inconsistency.
- `ngram-mod` acceptance was highly variable, including one zero-acceptance request.

## Grounding and recommendation

The model does not pass the hard grounding gate. The common retriever still did not enforce hardened-fix-first evidence, and its mean exact-path citation score was only 27.08.

Keep KAT as the sole primary worker. Qwen2.5-Coder 14B offers no useful advantage over KAT for this workload: similar VRAM, much lower throughput, lower production quality, and materially weaker citations. Do not change routing configuration from this result.
