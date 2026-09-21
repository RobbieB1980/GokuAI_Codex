# LegacyJavaConverter vNext Architecture Design

## Purpose

LegacyJavaConverter vNext will convert supported Forge and NeoForge projects and finished mod JARs to NeoForge 26.2 with reproducible, evidence-backed transformations. It will preserve the original mod's Java behavior, registrations, assets, data, models, items, entities, AI, and runtime semantics as closely as the target platform permits.

NeoForge 26.2 remains the target baseline. The existing 26.2 converter, solved conversions, `262r` corpus, mappings, exact source, and primer chain are valuable migration knowledge and must be retained while the implementation is hardened.

## Success Model

vNext reports separate outcomes rather than treating compilation as completion:

1. Intake and source profiling completed.
2. Deterministic conversion completed.
3. Destination Java parsed successfully.
4. `gradlew build` succeeded and produced `build/libs/*.jar`.
5. NeoForge client or server booted with the converted mod.
6. A world loaded without registry, datapack, or resource errors.
7. Representative content and behavior smoke tests passed.

A lower stage must never be described as satisfying a higher stage.

## Constraints

- Supported detected source versions are Minecraft 1.20.1 or newer.
- The target is Minecraft/NeoForge 26.2 using JDK 25.
- Inputs are never modified.
- Existing proven deterministic fixes remain active until an equivalent tested vNext implementation replaces them.
- Exact 26.2 physical source is authoritative for target API claims.
- Complex semantic code is never deleted or compile-gated merely to obtain a green build unless an explicit, reported compatibility policy permits it.
- GokuCodexAI is an escalation stage, not the first transformation engine.

## Architecture

### 1. Orchestrator

PowerShell remains the top-level Windows orchestration layer during the transition. It owns input validation, JAR extraction, artifact copying, dependency acquisition, process execution, reports, and compatibility with the existing GUI.

The 4,000-line conversion script will be decomposed incrementally. Existing entry-point scripts remain compatible while calling focused modules.

### 2. Conversion Manifest

Every run creates a stable machine-readable manifest before modifying the output. It records:

- input hashes and original artifact location;
- detected loader and exact Minecraft/NeoForge version;
- mod IDs, entry points, dependencies, and source sets;
- Java packages and declared types;
- registrations for blocks, items, entities, block entities, menus, sounds, and game rules;
- renderers, models, animations, AI goals, target selectors, brains, sensors, and behaviors when detectable;
- resource and data files with hashes and cross-references;
- selected migration route, recipes, overlays, evidence, and knowledge snapshot;
- validation results for every completion stage.

Dry-run produces this manifest and the planned recipe sequence without creating a converted project.

### 3. Deterministic Rule Engine

Rules have stable IDs, source applicability, target applicability, prerequisites, evidence, risk class, idempotence expectations, and validation requirements. The engine records which rule changed each file.

Rule order is:

1. Exact input fingerprint solution.
2. Exact source-version and mod solution.
3. General known deterministic rule.
4. AST recipe.
5. Narrow decompiler-damage text repair.
6. Unresolved issue classification.

Text replacement is permitted only for bounded cases with fixtures proving that comments, strings, unrelated identifiers, nested syntax, and repeated execution remain safe.

### 4. Java AST Engine

A JVM-based worker performs Java analysis and rewriting. JavaParser with symbol solving is the initial implementation because it supports focused embedding and direct control over decompiled or partially broken inputs. OpenRewrite recipes may be added for transformations where its semantic and Gradle models provide a clear advantage.

The AST worker returns structured results rather than editing silently:

- parsed files and parse failures;
- applied recipe IDs;
- diagnostics and unresolved symbols;
- changed file paths;
- before/after semantic inventory deltas.

Parse failures are quarantined for known-solution or bounded repair handling. They must not trigger broad global replacements.

### 5. Gradle Hardening

vNext transforms existing Gradle builds where possible instead of always replacing them. It preserves custom repositories, source sets, tasks, access transformers, mixin configuration, publishing, generated resources, and dependency intent.

When a source build cannot be transformed safely, the generated scaffold remains available as an explicit fallback. The report identifies every discarded or replaced construct.

The target profile pins NeoForge 26.2, ModDevGradle, Gradle wrapper, Java 25, dependency coordinates, and generated metadata in one versioned definition.

### 6. Unified Solutions Index

The executable Solutions Index unifies:

- `lib/SolvedConversionIndex.json`;
- mod-specific overlays;
- `C:\gokuai\Data\262r`;
- primer rules and dependency migration ledgers;
- negative rules and stop conditions;
- validation and runtime evidence from proven conversions.

Each entry records applicability, provenance, confidence, transformation implementation, regression fixtures, build status, and runtime status. A 26.2 build result is not automatically marked runtime-proven.

### 7. Preservation Pipeline

Before and after conversion, vNext inventories and compares:

- resources, assets, namespaces, hashes, and metadata;
- models, blockstates, textures, sounds, animations, and client item definitions;
- recipes, loot tables, tags, advancements, structures, dimensions, worldgen, and data packs;
- blocks, items, entities, attributes, spawn eggs, renderers, and registrations;
- AI goals, target selectors, brains, sensors, navigation, and behavior-related attributes;
- entry points, event listeners, network payloads, mixins, and integrations.

JSON and TOML are parsed structurally. Reference checks identify missing targets and unexplained losses. Intentional removals must be associated with a rule and surfaced in the report.

### 8. Validation

Validation is staged and produces machine-readable and human-readable reports:

- unit and golden transformation fixtures;
- idempotence checks;
- Java parse checks;
- Gradle configuration and full build;
- installable JAR inspection;
- bounded client/server startup;
- world-load and content smoke tests for maintained fixtures;
- project-specific gameplay checks where automation exists.

The initial fixture corpus is drawn from the proven conversions already named in the Solutions Index.

### 9. GokuCodexAI Escalation

Escalation occurs only after deterministic rules, AST recipes, and matching known solutions have run and validation has produced a minimized failure. The issue packet contains only relevant source, evidence, diagnostics, validation commands, and the required structured result.

AI output is treated as a proposed patch. It must pass the same deterministic tests and validation gates before it can be promoted into the Solutions Index.

## Migration Strategy

### Stage 0: Reproducible baseline

- Repair four-part NeoForge version normalization.
- Reconcile the installed converter's uncommitted hardened fixes with upstream.
- Establish one release/package manifest and eliminate version drift.
- Add focused tests for every reconciled fix.

### Stage 1: Manifest and rule provenance

- Introduce the conversion manifest schema.
- Record rule selection, file changes, input/output hashes, and validation state.
- Make dry-run emit a complete plan.

### Stage 2: AST foundation

- Add the JVM AST worker and protocol.
- Migrate package/import and `ResourceLocation` to `Identifier` transformations first.
- Run legacy and AST implementations against fixtures and compare results.

### Stage 3: Gradle hardening

- Introduce the versioned 26.2 target profile.
- Parse and preserve existing build intent.
- Retain scaffold generation as a reported fallback.

### Stage 4: Unified Solutions Index

- Normalize bundled solutions, overlays, `262r`, and validation evidence.
- Enforce known-solution lookup before new reasoning.

### Stage 5: Preservation validation

- Add structured asset, data, model, item, entity, and AI inventories.
- Detect missing references and unexplained losses.

### Stage 6: Runtime gates

- Add bounded launch, world-load, registry, resource, and behavior smoke tests.
- Report build and runtime results independently.

### Stage 7: Controlled AI escalation

- Generate minimized issue packets only after deterministic stages fail.
- Require validation before promoting AI-derived repairs.

## Initial Delivery Slice

The first implementation slice contains Stage 0 plus the interfaces required for Stage 1 and Stage 2 planning. It does not replace semantic renderer, registry, entity, or AI repairs until preservation fixtures cover them.

The slice is complete when the upstream and installed converter fixes are reconciled, regression tests are green, release contents are reproducible, and the AST worker boundary has executable contract tests.

