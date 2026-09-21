# EVE 27B XENO HAT DeepSeek V4 Flash — b11057 retest

The model completed all 12 grounded stage-3 requests at 32K context with all layers on CUDA0, Q8 K/V cache, medium reasoning capped at 384 tokens, and `ngram-mod`. KAT was restored afterward.

| Model | Production | Oracle | Mean latency | Completion tok/s | Citation score | JSON valid | Truncated | Approx. allocation* |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| EVE 27B | 88.28 | 80.38 | 32.86 s | 44.99 | 79.17 | 10/12 | 0/12 | 17,750 MiB |
| KAT reference | 79.69 | 74.39 | 11.42 s | 150.17 | 58.33 | 11/12 | 1/12 | 15,651 MiB |

\* Total GPU use minus the measured 1,054 MiB idle baseline.

## Findings

- EVE produced the best automated stage-3 quality and citation scores tested so far: +8.59 production and +5.99 oracle versus KAT.
- It was about 3.3 times slower than KAT in completion throughput and about 2.9 times slower per request.
- It consumed about 2.1 GiB more GPU memory than KAT at half KAT's context size.
- It completed every request without OOM, HTTP failure, or length truncation.
- Two responses were not strict JSON despite stopping normally.
- Registry production, both Gradle cases, data-components oracle, and capability production received full automated quality credit. Mapping repair remained weaker at 56.25 repair points in both modes.
- llama.cpp reported unused layer-64/`nextn` tensors, indicating embedded speculative-related tensors were not used by the `ngram-mod` configuration. This is the same warning class seen with the other dense 27B models.

## Hard grounding decision

EVE does not pass the deployment gate yet. The shared retriever still failed to enforce `Solved_Problems` first and supplied exact NeoForge 26.2 evidence in only 7/12 packets. The strong score therefore demonstrates relative synthesis and citation behavior, not verified target-native converter correctness.

## Recommendation

1. Keep KAT as the sole primary/default worker, as requested.
2. Preserve EVE as the first challenger worth a stricter follow-up. It is the only tested candidate to exceed KAT's automated grounded-quality score.
3. Do not change routing from this run. First rerun EVE and KAT using corrected hardened-fix-first retrieval and manually compile-check the registry, data-component, mapping, and capability repairs against exact NeoForge 26.2 sources.
4. If that stricter test holds, consider EVE only as an opt-in slow review/escalation worker; its latency and VRAM profile do not justify replacing KAT as primary.
