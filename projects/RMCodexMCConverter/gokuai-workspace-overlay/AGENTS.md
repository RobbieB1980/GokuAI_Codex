# LegacyJavaConverter vNext repair policy

## Authority and scope

Codex is the repair orchestrator. It owns routing, evidence selection, worker
delegation, integration, validation, and promotion of reusable fixes.

The primary route is Luna High (`gpt-5.6-luna-high`, high reasoning). For hard
issues, repeated failures, conflicting evidence, or an orchestrator failure,
preserve the evidence and hand off to Sol Medium (`gpt-5.6-sol-medium`, medium
reasoning). KAT and Qwen remain optional bounded local workers.

The target is NeoForge 26.2 only. Detect the actual source version and reject
pre-1.20.1 inputs. Do not silently retarget a repair to 26.3.

KAT and Qwen are optional bounded local workers. Give a worker one issue packet
at a time. Treat every worker result as a proposal until Codex reviews and
verifies it.

## Required order

1. Read `CODEX_REPAIR_REQUEST.md`, `SOURCE_PROFILE.json`,
   `MIGRATION_EVIDENCE.md`, `conversion-manifest.json`, and
   `compile-errors.log` when present.
2. Use the `legacy-java-converter-vnext` skill from `.agents/skills`.
3. Complete deterministic conversion stages before fresh reasoning.
4. Consult the Solutions Index, 262r, solved cases, the matching 26.2 primer
   ledger, mappings, and exact 26.2 physical sources in that order.
5. Use the JavaParser AST worker for structural Java edits and keep lexical
   transforms idempotent.
6. Reconcile assets, data, models, items, entities, AI, and behaviour against
   the source inventory.
7. Build with `tools/Build-WithDestinationJava.ps1` and the project wrapper.
8. Record build, launch, registry/data, content, and behaviour as separate
   validation gates.
9. Promote reusable repairs into converter logic or an AST recipe, the
   Solutions Index/262r, and a regression fixture.

## Knowledge and tools

Use the local `minecraft-knowledge` MCP configured in `.codex/config.toml`.
The active knowledge root is `C:\GokuCodexAI\Data`; do not walk the entire
tree when indexed retrieval can return a bounded result.

Read task-specific instructions from `.agents/skills`. Supporting knowledge
and worker contracts are under
`.agents/skills/legacy-java-converter-vnext/references`.

NeoForge 26.2 uses destination JDK 25 in this converter profile. A clean
Gradle build is not proof of runtime or behavioural correctness.
