# GokuAI Codex

Clean control plane for a persistent local GokuAI orchestrator with local
llama.cpp workers and Codex/ChatGPT as the senior escalation engine.

The original `C:\gokuai` repository is an external, read-only asset store.
This repository never writes to `C:\gokuai\.git` and does not duplicate model
weights or knowledge databases.

## Runtime layout

- Primary worker: `C:\gokuai\models\kat-reap50-Q6_K.gguf` (`goku-code`)
- Fast worker: `C:\gokuai\models\Nemotron-9B-OpenCode.Q8_0.gguf` (`goku-fast`)
- Runtime: `C:\gokuai\runtime\llama.cpp\llama-server.exe`
- Knowledge root: `C:\gokuai\Data`
- Active-index pointer: `C:\gokuai\DataIndex\minecraft-knowledge\_ACTIVE_DB.txt`

Both workers use all GPU layers, no CPU MoE offload, Q8 KV cache, flash
attention, and llama.cpp `ngram-cache` speculative decoding.

## Routing order

1. Check hardened fixes in `Data\Solved_Problems`.
2. Query compact, version-aware primer evidence.
3. Ground target-version claims in exact-version sources.
4. Ask the selected local worker to resolve the bounded issue.
5. Escalate unresolved or uncertain issues to Sol Medium.
6. Use Sol High only for repeated failure, conflicting evidence,
   multi-version architecture, subtle runtime bugs, or Medium uncertainty.

## Commands

```powershell
.\Validate-GokuAI.ps1
.\Start-GokuBackend.ps1
.\Start-GokuBackend.ps1 -ForceRestart
.\Stop-GokuBackend.ps1
```

