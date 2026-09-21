# vNext GokuCodexAI failure handoff design

## Goal

When a NeoForge 26.2 conversion cannot be completed deterministically, open
GokuCodexAI with the same version-controlled vNext process, tools, evidence,
and validation rules used by the converter. A clean Gradle build is an
intermediate result; runtime and behavioural correctness remain separate.

## Architecture

The repository-owned Goku workspace overlay is the canonical source for the
`legacy-java-converter-vnext` skill. The skill orchestrates the conversion in
this order:

1. Inspect source and generated evidence.
2. Consult the Solutions Index and 262r knowledge before fresh reasoning.
3. Apply deterministic transformations.
4. Use JavaParser-backed AST repair for structural Java changes.
5. Preserve and validate assets, data, models, items, entities, AI, and
   behaviour.
6. Validate packaging, a destination-JDK Gradle build, and then runtime and
   behavioural fidelity as distinct gates.
7. Escalate unresolved work to GokuCodexAI with a bounded evidence packet.

The existing `repair-failed-262-output` skill remains the focused entry point
for a failed output, and explicitly delegates overall orchestration to the new
vNext skill.

## Distribution and synchronization

Portable and installed converter layouts include:

- the complete `gokuai-workspace-overlay`;
- `Sync-GokuaiConverterWorkspace.ps1`;
- conversion manifests, deterministic transforms, and Solutions Index data;
- the JavaParser AST worker runtime.

`Sync-GokuaiConverterWorkspace.ps1` supports both repository and packaged
layouts. Before a repair prompt is created or GokuCodexAI is started,
`Open-GrokRepairSession.ps1` performs a full synchronization into the selected
workspace and verifies the required skill and repair tools. It fails closed if
the bundle is missing or incomplete, preventing a stale repair environment
from being opened.

## Handoff

The repair prompt names `legacy-java-converter-vnext` as the orchestration
skill and `repair-failed-262-output` as the failed-output playbook. The failed
project retains its source profile, migration evidence, compile errors, and
conversion manifest. GokuCodexAI opens only after synchronization,
verification, knowledge wiring, and prompt creation succeed.

## Testing

Automated tests exercise a portable-like layout and temporary workspace. They
verify that synchronization:

- works with spaces in paths;
- overwrites a stale skill;
- installs both repair skills and standing orders;
- installs the conversion manifest helper, AST bridge, and AST worker;
- rejects an incomplete source bundle;
- produces a prompt that invokes the skills in the required order.

The existing regression, transformation, manifest, AST worker, .NET build,
and portable-release checks remain mandatory.
