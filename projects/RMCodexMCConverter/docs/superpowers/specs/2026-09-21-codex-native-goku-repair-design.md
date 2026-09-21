# Codex-native GokuCodexAI repair architecture

**Status:** Proposed for written-spec review

**Date:** 2026-09-21

**Canonical product:** `RobbieB1980/LegacyJavaConverter`

**Converter release baseline:** 3.0.0

**Target platform:** NeoForge 26.2 (unchanged)

## 1. Purpose

LegacyJavaConverter must remove its operational dependency on Grok and make
GokuCodexAI the native repair environment for failed conversions. Codex is the
orchestrator. Local KAT and Qwen models remain optional, bounded workers. The
converter must continue to exhaust deterministic conversion, known solutions,
and structural AST repair before opening an AI repair session.

The result must preserve the vNext objective: convert a legacy mod as faithfully
as possible, including Java behavior, Gradle/build logic, mappings, assets,
models, items, entities, AI, and gameplay behavior. A clean Gradle build is a
separate result from a successful game launch or faithful runtime behavior.

This migration is broader than renaming the GUI button. All active converter
and GokuCodexAI paths, launchers, configuration, prompts, skills, tests,
packaging, and documentation must use the native Codex architecture.

## 2. Agreed constraints

- Keep `RobbieB1980/LegacyJavaConverter` as the canonical converter repository.
- Keep the current NeoForge 26.2 target. NeoForge 26.3 and its primer are not
  part of this change.
- Use `C:\GokuCodexAI` as the only active AI workspace root.
- Use Codex as the repair orchestrator.
- Keep KAT/Qwen as optional local workers with bounded issue packets.
- Remove all runtime dependence on `grok.exe`, `grok-home`, `GROK_HOME`, Grok
  authentication, Grok services, and Grok-specific configuration discovery.
- Preserve `C:\gokuai` during migration. Deletion or archival is a separate,
  explicitly approved operation after end-to-end validation.
- Preserve historical evidence accurately. Historical case names and source
  paths containing “Grok” may remain when they identify provenance, but they
  must not be active instructions or dependencies.
- Preserve the existing uncommitted work in `C:\GokuCodexAI`. Integration must
  be performed without overwriting or discarding it.

## 3. Options considered

### 3.1 Codex-native hybrid (selected)

Codex owns orchestration, evidence review, integration, and final verification.
KAT/Qwen can receive small, explicit worker requests. This preserves local
worker capability while establishing one accountable orchestrator and one
native configuration model.

### 3.2 Codex-only

This would be simpler but would discard the useful local-worker investment and
reduce offline/bounded repair capacity.

### 3.3 Local-model-first orchestration

This would retain Goku/KAT as the primary orchestrator and use Codex only for
escalation. It conflicts with the agreed requirement that Codex remain the
orchestrator and would perpetuate two competing control planes.

## 4. System ownership

### 4.1 LegacyJavaConverter

The canonical product owns:

- deterministic conversion and conversion manifests;
- JavaParser/OpenRewrite-style structural transformations;
- Gradle and destination-JDK hardening;
- resource and gameplay-surface inventory;
- Solutions Index queries and application of known fixes;
- failed-output evidence generation;
- the packaged Codex-native workspace overlay;
- the GUI repair entry point;
- validation and regression tests;
- installer and portable release contents.

### 4.2 GokuCodexAI

`C:\GokuCodexAI` owns:

- the native Codex launcher and workspace bootstrap;
- the local Minecraft knowledge MCP server and indexes;
- optional KAT/Qwen worker launchers and worker profiles;
- local model runtime management;
- repair-session monitoring and handoff artifacts;
- the machine-level copy of the shared conversion skill when required.

It does not own a divergent converter implementation.

### 4.3 RMCodexMCConverter

`C:\GokuCodexAI\projects\RMCodexMCConverter` is a migration source, not a
second product. Proven Codex-native launcher, watcher, prompt, and repair-flow
changes will be compared and deliberately ported into LegacyJavaConverter.
No bulk copy is permitted. After feature parity and validation, retirement of
the duplicate is a separate decision.

## 5. Native Codex surfaces

The migration must use Codex's documented native surfaces according to scope:

- `AGENTS.md` for durable repository workflow, evidence order, validation
  requirements, and orchestration rules.
- `.agents/skills/<skill-name>/SKILL.md` for repository-scoped reusable skills.
  This is the documented Codex repository skill location; `.grok/skills` and
  `.codex/skills` are not canonical skill locations.
- `.codex/config.toml` for trusted-project Codex settings and the
  `minecraft-knowledge` MCP declaration.
- `CODEX_REPAIR_REQUEST.md` for the failed conversion's bounded entry request.
- `.gokuai/issues/<issue-id>/` for local worker request/result contracts, since
  these are GokuCodexAI artifacts rather than Codex configuration.

The `legacy-java-converter-vnext` skill is canonical in the converter's
versioned `.agents/skills` overlay. The release sync process installs that same
version into repair workspaces. A personal user installation may exist for
convenience, but it is not the release source of truth.

## 6. End-to-end conversion and repair flow

### 6.1 Deterministic stages

The converter runs the following stages before AI escalation:

1. Identify source Minecraft version, loader, framework, mappings, dependencies,
   and target profile.
2. Inventory Java packages, Gradle files, metadata, assets, data packs, models,
   textures, recipes, tags, sounds, items, blocks, entities, renderers, AI goals,
   events, networking, capabilities/attachments, and other behavior surfaces.
3. Scaffold the NeoForge 26.2 destination with the pinned destination Java and
   supported Gradle/NeoGradle configuration.
4. Apply idempotent deterministic transforms.
5. Query and apply the persistent Solutions Index and exact matching 262r cases.
6. Apply structural Java/Gradle AST recipes where lexical transforms are unsafe.
7. Reconcile copied and generated resources against the source inventory.
8. Run validation and record the remaining failures with bounded evidence.

Only an unresolved result from these stages enables the repair action.

### 6.2 Failed-output preparation

The converter writes or refreshes:

- `CODEX_REPAIR_REQUEST.md`;
- `SOURCE_PROFILE.json`;
- `conversion-manifest.json`;
- `MIGRATION_EVIDENCE.md`;
- `EVIDENCE_PACKET.md`;
- `compile-errors.log`, when compilation failed;
- resource/gameplay preservation inventory and unresolved findings;
- validation status separating build, launch, registry/data, content, and
  behavior checks;
- the active target, mapping, primer, Solutions Index, and exact-source paths.

The packet must be bounded. It contains concise excerpts and paths rather than
the entire parent transcript or unbounded logs.

### 6.3 Workspace synchronization

Before Codex opens, a deterministic sync operation installs the versioned
native overlay into the repair workspace:

- root `AGENTS.md`;
- `.agents/skills/legacy-java-converter-vnext` and its required subordinate
  skills/references;
- `.codex/config.toml` containing the project MCP configuration;
- destination-Java build wrapper;
- JavaParser AST worker and conversion helper libraries required for repair;
- schema and manifest support;
- Solutions Index pointers and compact generated knowledge context.

The sync operation must be idempotent, validate required files and versions,
and fail visibly rather than silently opening a partially configured session.
Hand-maintained user data in the failed output must not be overwritten.

### 6.4 Codex launch

The GUI action and command-line path invoke `Open-CodexRepairSession.ps1`.
The launcher:

1. resolves and validates the failed output and canonical GokuCodexAI root;
2. runs the native workspace synchronization and preflight checks;
3. locates the installed Codex CLI without hard-coding one application version;
4. launches Codex with the failed output as the working directory and grants
   access only to the required converter/GokuCodexAI evidence roots;
5. points the opening task at `CODEX_REPAIR_REQUEST.md` and the vNext skill;
6. uses supported native Codex CLI/config options;
7. reports actionable installation/configuration errors when Codex or required
   local knowledge is unavailable.

The launch must not set `GROK_HOME`, invoke `grok mcp`, require Grok login, or
read `.grok` configuration.

### 6.5 Codex orchestration

Codex follows this order:

1. Verify source identity and the failed-output evidence.
2. Consult the persistent Solutions Index, 262r, solved cases, matching primer
   ledger, and exact 26.2 physical sources.
3. Re-run or complete deterministic and AST-capable work before fresh reasoning.
4. Audit resource and gameplay preservation.
5. Delegate only bounded, evidence-backed issues to local workers when useful.
6. Review and integrate worker proposals; workers never become authoritative.
7. Run the destination-JDK build and separate runtime/content/behavior gates.
8. Encode durable discoveries into converter logic, Solutions Index/262r, and a
   regression fixture.

### 6.6 Local worker contract

KAT is the default local mechanical/code worker. Qwen is an optional local
quality escalation or review worker. Each request contains one issue, explicit
acceptance criteria, exact evidence paths, a minimal failure excerpt,
validation commands, and a result path.

Workers return structured results under `.gokuai/issues/<issue-id>/result.json`
with status, diagnosis, proposed or changed files, evidence, validation,
remaining risks, and confidence. Codex reviews every result. Local worker
failure, timeout, or absence must not corrupt the workspace and must fall back
to Codex handling the issue directly.

## 7. Naming and compatibility migration

All active product language will use the following names:

| Old active name | New active name |
| --- | --- |
| Fix in Grok | Repair with GokuCodexAI |
| `Open-GrokRepairSession.ps1` | `Open-CodexRepairSession.ps1` |
| `GROK_REPAIR_PROMPT.md` | `CODEX_REPAIR_REQUEST.md` |
| `Get-GrokRepairPromptBody` | `Get-CodexRepairRequestBody` |
| `Write-GrokRepairPrompt` | `Write-CodexRepairRequest` |
| `.grok/skills` | `.agents/skills` |
| `.grok/config.toml` | `.codex/config.toml` |
| Grok rules/workflows | `AGENTS.md`, skills, scripts, and references |
| `C:\gokuai` active root | `C:\GokuCodexAI` active root |

For one compatibility release, an `Open-GrokRepairSession.ps1` wrapper may
remain if existing installed copies or scripts require it. The wrapper must
emit a deprecation notice and forward only to the native Codex launcher. It
must contain no Grok runtime logic. Internal APIs may retain temporary aliases
only when tests prove that removing them would break supported automation.

Historical changelog entries, archived case titles, and literal source paths
remain unchanged when rewriting them would falsify history. Current README,
usage, release, GUI, error, help, build, test, and knowledge instructions must
not describe Grok as an active system.

## 8. Knowledge, mappings, primers, and Solutions Index

The knowledge MCP remains local and rooted at `C:\GokuCodexAI`. Its project
configuration is expressed in `.codex/config.toml`. Repair sessions must query
compact indexed metadata first and open exact evidence files only as needed.

The Solutions Index must become an executable, persistent first-class stage,
not merely documentation. It unifies:

- converter hardened fixes;
- 262r remaps and prohibitions;
- solved conversion cases;
- source/target dependency deltas;
- mappings and exact physical sources;
- NeoForge 26.2 primer ledgers;
- AST recipe identifiers and applicability predicates;
- validation outcomes and regression fixtures.

Every entry needs stable identity, source/target applicability, evidence,
action/recipe, validation, provenance, and confidence. Knowledge updates must
be reproducible and versioned. A new primer or NeoForge version is ingested as
new versioned data; it does not silently retarget the 26.2 converter.

## 9. Security and external-dependency boundary

“No Grok dependency” means the repair path works without any xAI/Grok binary,
account, token, API, service, or configuration. It does not mean Codex itself is
offline. Codex is the selected orchestrator and uses the user's existing Codex
authentication. Minecraft knowledge retrieval and KAT/Qwen inference remain
local.

The launcher must avoid embedding credentials, widening filesystem access
beyond the repair and evidence roots, or changing user-global Codex settings.
Project `.codex/config.toml` is trusted-project configuration and must be
validated before launch. Destructive cleanup of the old root is outside scope.

## 10. Error handling

Preflight failures must distinguish:

- missing Codex installation or authentication;
- missing/untrusted project configuration;
- missing GokuCodexAI root or knowledge MCP runtime;
- stale or incomplete overlay synchronization;
- absent destination Java or Gradle prerequisites;
- malformed evidence or conversion manifest;
- unavailable local worker;
- build failure;
- runtime or behavioral failure after a clean build.

Errors should tell the user what failed, what remains safe, and the precise next
action. A failed worker is recoverable. A failed sync prevents launch. A clean
build never suppresses unresolved runtime/content/behavior findings.

## 11. Test and validation strategy

### 11.1 Static and unit coverage

- No active scripts or application code invoke `grok.exe`, `grok mcp`,
  `grok-home`, or `GROK_HOME`.
- Native skill layout, front matter, references, and discovery are linted.
- Prompt/request generation is deterministic and uses native names/paths.
- Overlay sync is idempotent and detects missing/stale required files.
- Compatibility wrappers forward to Codex and contain no legacy runtime logic.
- Release manifests include all required native files.

### 11.2 Handoff integration coverage

A disposable failed-output fixture must prove that repair preparation:

- preserves user project files;
- installs `AGENTS.md`, `.agents/skills`, and `.codex/config.toml`;
- creates the complete evidence/request packet;
- resolves `C:\GokuCodexAI` rather than `C:\gokuai`;
- performs a launcher preflight without opening an interactive session;
- identifies the Codex CLI without relying on a fixed WindowsApps version;
- exposes local workers as optional rather than mandatory.

### 11.3 Converter regression coverage

The existing regression, transformation, manifest, handoff, and AST suites must
remain green. New fixtures must exercise known-solution-first ordering, AST
idempotence, resources, models, items, entities, AI goals/behavior, and the
separation of build and runtime results.

### 11.4 End-to-end acceptance

Build a 3.0.0 installer and portable release, install them in a clean test
location, run a representative successful conversion, and deliberately produce
a failed conversion. The failure must open a native Codex repair workspace with
the full vNext skill and evidence. Validate at least one bounded local-worker
round trip and one Codex-only fallback.

The release report records independently:

- deterministic stages completed;
- known-solution and AST changes applied;
- asset/data/model/item/entity/AI/behavior preservation status;
- clean Gradle build and artifact;
- runtime launch and registry/data loading;
- content and behavioral checks;
- remaining manual work;
- fixes written back to tests and Solutions Index.

## 12. Documentation and release scope

Update all active documentation, help text, screenshots or labels, release
notes, packaging manifests, knowledge instructions, and test names that still
present Grok as active. Add a migration note explaining the compatibility
wrapper and the retained historical evidence. Keep the public product version
at 3.0.0 unless implementation reveals a release-policy reason to increment it;
the goal is to make the already-approved 3.0.0 architecture internally
consistent before a new installer is published.

## 13. Staged implementation

### Stage 1: Baseline and protected integration

- Create an isolated LegacyJavaConverter worktree.
- Inventory and classify every Grok reference as active, compatibility, or
  historical.
- Snapshot/record the dirty `C:\GokuCodexAI` state without modifying or
  discarding unrelated work.
- Establish failing tests for native names, paths, skill layout, and preflight.

### Stage 2: Native converter contract

- Add native request-generation APIs and launcher.
- Change GUI, converter failure flow, release manifest, and packaging.
- Add a deprecation-only compatibility wrapper where required.
- Convert tests from `.grok` assumptions to native Codex surfaces.

### Stage 3: Native workspace overlay and skill migration

- Convert the overlay to `AGENTS.md`, `.agents/skills`, `.codex/config.toml`,
  and supporting scripts/references.
- Port every still-relevant Grok rule, agent role, workflow, prompt, and tool
  instruction into the appropriate native surface.
- Verify skill discovery and MCP availability from a generated repair workspace.

### Stage 4: GokuCodexAI control-plane alignment

- Update GokuCodexAI authority rules so Codex is the orchestrator.
- Replace old sync fallbacks and roots with canonical converter/overlay inputs.
- Harden Codex launch, KAT/Qwen bounded worker contracts, watchers, and failure
  fallback.
- Port proven RMCodexMCConverter pieces intentionally and record provenance.

### Stage 5: Knowledge and Solutions Index integration

- Make lookup order executable and observable.
- Validate NeoForge 26.2 primer, mappings, dependency deltas, and exact-source
  pointers.
- Ensure durable repair promotion updates deterministic logic, index/262r, and
  regression fixtures together.

### Stage 6: Full verification and release

- Run all automated suites and static legacy-dependency scans.
- Run successful and failed conversion end-to-end tests.
- Validate build and runtime/behavior separately.
- Build and smoke-test installer and portable artifacts.
- Review remaining historical Grok references and ensure none are operational.
- Publish only after explicit approval of test evidence and artifacts.

## 14. Acceptance criteria

The migration is complete when:

1. The converter exposes **Repair with GokuCodexAI** and opens native Codex.
2. No active path requires Grok software, authentication, services, variables,
   or configuration.
3. `C:\GokuCodexAI` is the only active AI root.
4. Codex is unambiguously the orchestrator; KAT/Qwen are optional workers.
5. A failed output receives the complete, versioned vNext workspace and evidence
   packet automatically.
6. The Solutions Index is consulted before fresh reasoning.
7. Java and Gradle structural repairs use AST-capable mechanisms where required.
8. Assets, models, items, entities, AI, and behavior have explicit preservation
   evidence rather than being inferred from compilation.
9. Clean-build, launch, registry/data, content, and behavioral results are
   reported separately.
10. Durable AI-assisted repairs are promoted into deterministic logic,
    Solutions Index/262r, and regression tests.
11. The installer and portable package contain and validate the native repair
    flow.
12. Existing uncommitted GokuCodexAI work and the old `C:\gokuai` root are
    preserved until separately reviewed.

## 15. Out of scope

- Upgrading the target from NeoForge 26.2 to 26.3.
- Deleting `C:\gokuai` or the RMCodexMCConverter tree.
- Replacing Codex with a fully offline orchestrator.
- Automatically declaring gameplay correctness solely from a build result.
- General converter refactoring unrelated to the native repair architecture.
