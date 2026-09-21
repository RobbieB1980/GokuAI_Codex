---
name: legacy-java-converter-vnext
description: >-
  Orchestrate a faithful Legacy Java Converter migration or failed conversion
  repair to NeoForge 26.2. Use when converting a supported Forge/NeoForge Java
  mod, continuing from converter evidence, deciding between deterministic and
  AST repair, preserving gameplay resources or behaviour, or escalating an
  unresolved conversion to GokuCodexAI.
---

# Legacy Java Converter vNext

Own the complete conversion outcome. Treat the converter, known solutions,
AST worker, and GokuCodexAI as ordered stages, not interchangeable guesses.

## Scope

- Target Minecraft/NeoForge 26.2 only. Do not silently upgrade to 26.3.
- Preserve the original mod's intent, content, assets, and behaviour.
- Keep build success and runtime correctness as separate gates.
- Prefer reusable fixes over project-only patches.

## Required order

1. Read `AGENTS.md`, `CODEX_REPAIR_REQUEST.md`, `SOURCE_PROFILE.json`,
   `MIGRATION_EVIDENCE.md`, `conversion-manifest.json`, and
   `compile-errors.log` when present.
2. Confirm source version, loader, framework, target, and recommended passes.
   Do not edit while source identity is uncertain.
3. Build a bounded evidence packet. Consult the persistent Solutions Index,
   262r, solved cases, the matching primer ledger, and exact 26.2 physical
   sources in that order.
4. Re-run or complete deterministic conversion stages before fresh reasoning.
   Do not replace a known transform with a one-off manual edit.
5. Use the JavaParser AST worker for structural Java edits. Keep text/regex
   transforms limited to proven lexical changes and test idempotence.
6. Audit resources and gameplay surfaces against the source inventory. Read
   [preservation-and-validation.md](references/preservation-and-validation.md).
7. Validate the destination-JDK Gradle build. Then separately record runtime
   launch, registry/data loading, content, and behavioural results.
8. Escalate only unresolved, evidence-backed work. Read
   [escalation.md](references/escalation.md).
9. Encode every durable repair into the converter and Solutions Index/262r,
   add a regression fixture, and re-run the affected validation ladder.

For stage ownership and stop conditions, read
[pipeline.md](references/pipeline.md).

## Failed outputs

For a converter-created failed output, use `repair-failed-262-output`
under this skill's orchestration. Keep the failed output as the working project
and preserve its evidence files. Use `validate-destination-build` for every
Gradle validation and `encode-262r-remap` for reusable discoveries.

## Completion report

Report these independently:

- deterministic conversion stages completed;
- known-solution and AST changes applied;
- assets/data/models/items/entities/AI/behaviour preservation status;
- clean Gradle build and produced jar;
- runtime launch and behavioural validation status;
- remaining manual or GokuCodexAI work;
- reusable fixes written back to tests and the Solutions Index.

Never describe a clean build alone as a successful conversion.
