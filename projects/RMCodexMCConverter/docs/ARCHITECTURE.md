# Converter architecture

The converter uses two independent forms of evidence before changing Java code:

1. **Source metadata** — `gradle.properties`, Gradle dependencies, Forge/NeoForge TOML dependency ranges, loader files, and Java imports.
2. **API feature inventory** — scans Java sources for old package names and API families such as Forge imports, SRG names, legacy tick events, old NBT access, event subscribers, registries, capabilities, GUI rendering, and GeckoLib 4.

The result is written to `SOURCE_PROFILE.json`. It contains the detected source version, loader, confidence, route, evidence, matched API features, and planned migration passes.

`lib/PrimerChangeIndex.json` stores the ordered migration deltas and executable rule IDs. The final project receives `PRIMER_CHANGE_INDEX.md` containing only the transitions between its detected source and 26.2. Official primer transitions link to NeoForged; the unpublished 1.20.1–1.20.4 interval is explicitly labeled as a converter-maintained bridge.

Convert also writes an incremental **migration evidence packet** (`MIGRATION_EVIDENCE.md` / `.json`):

1. **NeoForge** — compact `primer_changes` index/shards (station `knowledge/NeoForge_Primers/26.2` preferred; bundled `lib/primer_changes/` stubs offline), query-filtered by detected API features.
2. **GeckoLib** — when hard-dep signals fire, attach `lib/dep_changes/geckolib` (4 → 5.5.3) alongside the `geckolib` pass.
3. **MCreator** — when `net.mcreator.` / framework signals fire, attach `lib/dep_changes/mcreator` bands; station upstream generators live under `knowledge/_upstream/mcreator` (see `MCreator-generator-delta-catalog.md`).

The packet is advisory provenance for agents and repair. ExactPrimer, GeckoLib, and MCreator PowerShell passes remain the executors.

The selected path is cumulative. For example, a detected 1.21.1 input receives the rules attached to every transition after 1.21.1, while a 1.21.11 input skips rules for APIs already changed in earlier releases. Shared mechanical rules remain general; narrowly semantic replacements live in version-and-mod-specific overlays and only run after both identities match.

## Cumulative routes

| Detected input | Route | Intended migration |
|---|---|---|
| Forge 1.20.1 | `forge-1.20.1` | Full SRG/Forge/API/MCreator chain to 26.2 |
| NeoForge 1.21.x | `neoforge-1.21.x` | 1.21-era API and MCreator passes, then 26.2 passes |
| NeoForge 22.x–25.x | `neoforge-22-to-25` | Common feature-driven 26.2 passes |
| NeoForge 26.0–26.1 | `neoforge-26.0-26.1` | Common 26.2 delta; skips old MCreator residue passes |
| NeoForge 26.2 | `already-26.2` | Conservative scaffold/registry/assets checks only |
| Fabric/Quilt | `unsupported-fabric-quilt` | Decompile is allowed; conversion stops clearly |
| Missing/mixed metadata | `generic-forge-neoforge` | Broad fallback supplemented by API feature evidence |

Routes control which rewrite functions run. Feature evidence can add a required pass when metadata is missing or decompiled sources mix APIs from multiple eras.

## Pipeline

1. JAR extraction and Vineflower decompilation (JAR mode)
2. Loader/version detection and API inventory
3. Source/resource layout and complete non-class resource copy
4. Dependency discovery and acquisition plan
5. NeoForge 26.2 ModDevGradle scaffold
6. Ordered, exact-version primer rules followed by route/feature-aware Java migration passes
7. Registry, mod entry point, event bus, assets, and client item repair
8. Optional `compileJava`
9. `COMPILE_REPORT.md`, `COMPILE_REPORT.json`, and full `compile-errors.log`

## vNext foundation boundary

The vNext foundation introduces two additional, deliberately separated layers:

1. `lib/ConversionManifest.ps1` records deterministic input files, hashes, selected rules, and ordered validation results in a stable machine-readable contract.
2. `tools/ast-worker` uses JavaParser 3.28.2 with symbol solving to analyze Java sources through a versioned JSON protocol. `lib/AstWorkerBridge.ps1` invokes it without placing source or dependency paths in a shell command and can compare its type/import inventory with the legacy source scan.

AST operation is currently **shadow-only**. It reports parsed files, per-file parse failures, declared types, imports, diagnostics, and inventory differences. It does not yet edit Java files or replace the deterministic PowerShell migration passes. Parse failures are preserved for later known-solution or bounded-repair handling; they do not trigger broad replacement.

The worker and Windows release both target the NeoForge 26.2 toolchain and resolve JDK 25 explicitly. The portable release includes the worker runtime and its Java dependencies under `tools/lib/ast-worker`.

## Validation stages

Completion is reported as a ladder, never as one success flag:

1. Input profiling and deterministic planning completed.
2. Deterministic conversion completed.
3. Destination Java parsed successfully, with parse failures reported separately.
4. The converted project completed `gradlew build` and produced an installable JAR.
5. NeoForge booted with that JAR.
6. A world loaded without registry, datapack, or resource errors.
7. Representative content and behavior checks passed.

Building this converter or its portable package validates the converter distribution only. It does not establish stages 4-7 for any converted mod. See `docs/VNEXT-STATUS.md` for the current foundation evidence and validation commands.

## Important boundary

This is a deterministic migration assistant, not a universal semantic Java translator. It can identify and rewrite known API patterns. Complex mixins, networking, custom render pipelines, capabilities/transfer code, world generation, and decompiler damage may still require targeted rules or manual work. A green `compileJava`, `build`, and `runClient` test remain the completion criteria for each converted mod.

When a new migration failure is fixed, add its detection pattern and regression fixture before broadening a rewrite. This keeps newer sources from receiving destructive old-version substitutions.
