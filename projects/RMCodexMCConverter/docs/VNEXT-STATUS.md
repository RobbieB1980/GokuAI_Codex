# LegacyJavaConverter vNext foundation status

## Baseline

- Product version: `3.0.0`
- Target: Minecraft / NeoForge `26.2` using NeoForge `26.2.0.72`
- Destination Java: JDK 25
- Working branch: `vnext`
- Input projects and JARs remain read-only; conversion writes to a separate output tree.

The target remains 26.2. The 26.3 primer and beta line are not part of this foundation slice.

## Implemented in this slice

- Four-component NeoForge versions are preserved during normalization.
- Installed hardened 26.2 leaf, configured-feature, and client-item fixes are reconciled into source with fixtures and idempotence checks.
- Product version metadata and portable release contents have one authoritative definition.
- Golden text-transformation fixtures expose both intended rewrites and the current comment/string limitation for later AST replacement.
- A stable conversion-manifest schema records input hashes, rule provenance, and ordered validation states.
- A JavaParser 3.28.2 worker analyzes Java with source and JAR type solvers through protocol version 1.
- A PowerShell 5.1 bridge sends UTF-8 JSON over redirected stdin/stdout, preserves per-file parser diagnostics, and performs a read-only legacy-versus-AST inventory comparison.
- The portable release includes the AST worker distribution and runtime dependencies.
- A shared `legacy-java-converter-vnext` skill defines deterministic-first orchestration, preservation checks, validation gates, and bounded GokuCodexAI escalation.
- Repair with GokuCodexAI synchronizes and verifies native `AGENTS.md`, `.agents/skills`, `.codex/config.toml`, current converter libraries, conversion-manifest support, and the AST worker before opening Codex as orchestrator.

## Current execution boundary

Production conversions continue to use the proven deterministic PowerShell migration passes and exact known solutions. The AST worker is analysis-only and shadow-only: it does not rewrite source, choose routes, or suppress existing deterministic fixes.

This is intentional. AST recipes will replace individual text rewrites only after fixtures prove preservation of comments, strings, unrelated identifiers, nested syntax, malformed-source quarantine, and idempotence.

GokuCodexAI remains an escalation stage. It is not invoked before deterministic rules, known solutions, AST-capable recipes, and validation diagnostics have been exhausted.

## Validation ladder

These outcomes are distinct:

1. Source intake and profiling completed.
2. Deterministic conversion completed.
3. Destination Java parsed; any quarantined files are listed.
4. The converted mod completed `gradlew build` and produced `build/libs/*.jar`.
5. NeoForge client or server booted with the converted mod.
6. A world loaded without registry, datapack, or resource errors.
7. Representative assets, models, items, entities, AI, and behavior passed smoke checks.

A successful converter solution build or portable-package build proves only that the converter itself can be built and packaged. It does not prove that an arbitrary converted mod builds, launches, loads a world, or behaves correctly in game.

## Reproduce foundation verification

The complete gate was run on 2026-09-21 with these results:

- regression suite: 156 passed;
- Goku failure-handoff suite: 20 passed;
- golden transformation suite: 3 passed;
- conversion-manifest suite: 21 passed;
- AST bridge suite: 15 passed;
- Java worker: Gradle clean, test, and install distribution succeeded;
- Windows solution: Release build succeeded with 0 warnings and 0 errors;
- portable and installer release assembly succeeded;
- the assembled portable tree passed the portable-manifest check.

These results verify the vNext foundation and its distributable converter artifacts. They are not an in-game validation result for a converted mod.

Run from the repository root in Windows PowerShell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests\Run-RegressionTests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests\Run-TransformationTests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests\Run-ManifestTests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests\Run-CodexHandoffTests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests\Run-AstBridgeTests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests\Run-CodexNativeAuditTests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\Build-AstWorker.ps1
dotnet build RB.LegacyJavaConverter.slnx -c Release
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\Build-Release.ps1 -SkipWorkspaceSync
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\Test-PortableManifest.ps1 `
  -Root dist\portable\RB-Legacy-Java-Converter `
  -ManifestPath eng\portable-manifest.json `
  -Layout Portable
```

`Build-AstWorker.ps1` selects destination JDK 25 and uses the checked-in Gradle 9.2.1 wrapper, so verification does not depend on the machine's ambient Java 8 installation or a global Gradle command.

Release builds package and validate the native overlay without modifying the live GokuCodexAI workspace. Failed-output preparation performs the synchronized installation when repair is requested.

## Next implementation stages

1. Promote package/import and `ResourceLocation` to `Identifier` migrations into fixture-backed AST recipes.
2. Harden existing Gradle builds while preserving repositories, tasks, source sets, mixins, access transformers, publishing, and generated resources; retain scaffold generation as an explicit fallback.
3. Unify bundled solutions, overlays, primer evidence, and the `262r` corpus into one executable Solutions Index consulted before fresh reasoning.
4. Add before/after inventories for assets, data, models, items, registrations, entities, renderers, AI goals, brains, sensors, and behaviors.
5. Add bounded NeoForge boot, world-load, registry/resource, and representative gameplay smoke gates.
