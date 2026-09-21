# KAT context-capacity recommendation

KAT declares a native training context of 262,144 tokens (`qwen35moe.context_length`, `n_ctx_train`, and `n_ctx_orig_yarn` all equal 262,144). No RoPE extrapolation is required up to that size.

All probes used one slot, all model layers and KV on CUDA0, Q8 K/V cache, flash attention, automatic fitting disabled, and a short inference validation.

| Context | GPU used | Free VRAM | Allocation above 1,543 MiB idle | Startup | Inference |
|---:|---:|---:|---:|---:|---:|
| 98,304 | 17,661 MiB | 6,903 MiB | 16,118 MiB | 6.95 s | Pass |
| 131,072 | 18,124 MiB | 6,440 MiB | 16,581 MiB | 6.83 s | Pass |
| 163,840 | 18,592 MiB | 5,972 MiB | 17,049 MiB | 6.84 s | Pass |
| 196,608 | 19,060 MiB | 5,504 MiB | 17,517 MiB | 6.86 s | Pass |
| 229,376 | 19,528 MiB | 5,036 MiB | 17,985 MiB | 6.82 s | Pass |
| 262,144 | 19,996 MiB | 4,568 MiB | 18,453 MiB | 6.87 s | Pass |

Measured Q8 KV/context growth was approximately 468 MiB per additional 32,768 tokens, or about 14.3 KiB per context token.

## Recommendation

- Production optimum: 196,608 tokens. This provides three times the current 65,536 capacity while retaining approximately 5.5 GiB free in the measured desktop state.
- Conservative optimum: 131,072 tokens. Use this if other GPU applications frequently consume several GiB.
- Validated maximum/native capacity: 262,144 tokens. It fits and performs inference, retaining approximately 4.6 GiB, but offers less protection against unrelated GPU-memory spikes.
- Keep `parallel=1`, Q8 K/V, flash attention, all layers on CUDA0, and `fit=off` so the server cannot silently reduce context or offload placement.
- Reserve output inside the context budget. With `max_tokens=8192`, a 196,608-token slot should admit no more than roughly 188,416 prompt tokens before template overhead and safety allowance. A practical input cap is 180,000 tokens.

The active configuration was not changed by this capacity test. KAT was restored at 65,536 tokens after probing.
