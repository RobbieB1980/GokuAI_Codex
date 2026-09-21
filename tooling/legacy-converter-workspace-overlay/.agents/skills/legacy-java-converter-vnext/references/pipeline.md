# vNext pipeline and ownership

## Stage 1: profile and inventory

Detect the actual source version, loader, generator/framework, dependencies,
Java level, namespaces, and content inventory. Preserve source evidence and
record uncertainty instead of guessing.

## Stage 2: persistent knowledge

Consult, in order: the failed-output packet, `SolvedConversionIndex.json`,
262r converter rules and one matching shard, solved projects, one matching
primer ledger, then exact target sources. A match must cite its rule or case.

## Stage 3: deterministic conversion

Run the route-specific Java, Gradle, mapping, dependency, metadata, asset, and
data passes. Every transform must be repeatable and preferably idempotent.

## Stage 4: structural repair

Use the JavaParser worker for imports, declarations, calls, types, and other
syntax-aware edits. If AST confidence is insufficient, emit diagnostics and
leave the source unchanged for escalation.

## Stage 5: preservation audit

Compare source and output inventories. Missing files, registrations, recipes,
models, entities, renderers, goals, interactions, or data are conversion
failures even when Java compiles.

## Stage 6: validation

Pin JDK 25, run the project wrapper's full `build`, confirm the expected jar,
then perform runtime and behavioural checks as independent evidence.

## Stage 7: escalation and learning

Escalate only the unresolved family with a bounded packet. Review the repair,
validate it, then encode a reusable solution and regression test.
