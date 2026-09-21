# Small GGUF b11057 retest

Both models were tested one at a time with all layers on CUDA0, no CPU MoE/FFN offload, 32K context, Q8 K/V cache, medium reasoning capped at 384 tokens, and `ngram-mod`. KAT was restored afterward.

| Model | Production | Oracle | Mean latency (prod/oracle) | Completion tok/s | Citation score | JSON valid | Truncated | Approx. model allocation* |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| OmniCoder 9B Q8_0 | 68.76 | 66.44 | 14.82 / 13.82 s | 85.04 | 19.05 | 12/12 | 0/12 | 10,022 MiB |
| DeepSeek-R1 Distill Qwen 14B Q6_K | 69.96 | 59.66 | 20.31 / 18.27 s | 60.27 | 16.67 | 3/12 | 0/12 | 15,557 MiB |

\* Total GPU use minus the previously measured 1,054 MiB idle baseline.

For reference, KAT scored 79.69 production / 74.39 oracle at about 150 completion tokens/sec with a 58.33 citation score.

## Findings

- OmniCoder is the better small-worker candidate. It returned valid JSON for every case, never truncated, used about 10 GiB, and ran at 85 tokens/sec. Its repair grounding is materially below KAT, especially registry migration and exact citations.
- DeepSeek had a slightly higher production score but a much worse oracle score and emitted valid strict JSON in only 3/12 cases. It is slower, uses roughly 5.5 GiB more VRAM than OmniCoder, and is not suitable for the bounded JSON worker contract in this configuration.
- OmniCoder warned that `cache_reuse` is unsupported by its context, so llama.cpp disabled that feature. This was non-fatal.
- DeepSeek warned that its `</s>` token was not marked as a control token and llama.cpp overrode it. This points to GGUF tokenizer metadata inconsistency and should be treated as a packaging risk.
- Both models completed 12/12 HTTP requests without OOM or request failure. `ngram-mod` was active and logged variable acceptance.

## Grounding gate

Neither model passes the hard grounding gate. The common stage-3 retriever still produced 94% keyword recall but did not enforce hardened-fix-first retrieval, and exact-path citation adherence was only 19.05 for OmniCoder and 16.67 for DeepSeek.

## Recommendation

1. Keep KAT as the default worker.
2. Retain OmniCoder as a possible low-VRAM mechanical/formatting worker, not as a NeoForge API authority.
3. Do not route converter repair or review work to this DeepSeek build in its current form.
4. If OmniCoder is tested further, disable unsupported `--cache-reuse`, keep reasoning modest, and focus its suite on mechanical Java repair and deterministic JSON rather than evidence-sensitive migration.
5. Do not modify routing configuration from this result alone.
