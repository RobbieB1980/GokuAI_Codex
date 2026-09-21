# GokuCodexAI

Codex-first control plane for faithful Legacy Java Converter repair. Codex owns
the evidence, repair strategy, integration, and validation cycle. Local KAT and
Qwen models are optional bounded workers; their absence or failure never blocks
Codex from continuing the repair.

The configured orchestrator is Luna High (`gpt-5.6-luna-high`, high reasoning).
Hard issues, repeated failures, conflicting evidence, and orchestrator failures
fall back to Sol Medium (`gpt-5.6-sol-medium`, medium reasoning).

Everything required by the active control plane is rooted beneath
`C:\GokuCodexAI`. The preserved earlier tree is not an active dependency.

## Repair order

1. Run deterministic conversion and retain its evidence packet.
2. Consult the executable Solutions Index and hardened fixes.
3. Ground changes in exact-version NeoForge 26.2 sources and mappings.
4. Apply Java/Gradle AST repair only when earlier stages are insufficient.
5. Preserve assets, models, items, entities, AI, and behaviour.
6. Optionally ask KAT or Qwen one bounded question; Codex reviews the result.
7. Report build, launch, registry/data, content, and behaviour gates separately.

## Runtime layout

- Root: `C:\GokuCodexAI`
- Knowledge: `C:\GokuCodexAI\Data`
- Active index: `C:\GokuCodexAI\DataIndex\minecraft-knowledge-local\_ACTIVE_DB.txt`
- Optional KAT worker: `models\kat-reap50-Q6_K.gguf`
- Optional Qwen reviewer: `models\Qwen3.8-27B-Q4_K_M.gguf`

## Commands

```powershell
.\Validate-GokuAI.ps1
.\Update-GokuKnowledge.ps1
.\Start-GokuBackend.ps1
.\Switch-GokuWorker.ps1 -Profile qwen38
.\Stop-GokuBackend.ps1
```

## Legacy Java Converter

Conversion failures write `CODEX_REPAIR_REQUEST.md`. The **Repair with
GokuCodexAI** button opens the failed output in Codex, where the bundled
`legacy-java-converter-vnext` skill governs deterministic-first repair,
preservation, and independent runtime validation.

`scripts\Sync-LegacyConverterWorkspace.ps1` consumes the converter's canonical
Codex-native overlay and verifies `AGENTS.md`, `.agents\skills`, and
`.codex\config.toml`. It does not copy legacy agent configuration.
