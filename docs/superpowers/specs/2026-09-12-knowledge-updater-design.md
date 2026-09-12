# Complete Minecraft Knowledge Updater Design

## Objective

Provide one explicit, operator-run command that safely refreshes GokuAI's local Minecraft migration knowledge. The command must update canonical upstream sources, rebuild derived mapping and search indexes, validate the result, and preserve the last known-good indexes when a stage fails.

Scheduling is not installed or modified. The operator runs the command manually.

## Scope

The refresh covers:

- NeoForge primers and documentation
- NeoForge, NeoForm, and ModDevGradle source repositories
- Gradle, Forge, GeckoLib, MCreator, and MCPConfig repositories
- Mojang version metadata, client JARs, and official client mappings from Minecraft 1.12 onward
- MCP stable 39 names for Minecraft 1.12.2
- the compact obfuscated/SRG/MCP/official mapping crosswalk
- the general full-text knowledge index
- status, provenance, and validation reports

Snapshots are included by default. Dedicated-server artifacts remain an explicit command-line option. Exact-version source trees already present under `Data/Exact_Version_Sources` are indexed and audited for freshness, but this first completed pipeline will not synthesize or switch their branches automatically; that requires a separate version-selection policy.

## Operator Interface

Create `Update-GokuKnowledge.ps1` at the repository root. Its default invocation is:

```powershell
.\Update-GokuKnowledge.ps1
```

Supported switches:

- `-ReleaseOnly`: exclude Mojang snapshots.
- `-IncludeServerArtifacts`: retain and index dedicated-server JARs and mappings.
- `-SkipSourceUpdate`: rebuild derived data from current local sources without network access.
- `-ReportPath <path>`: override the default timestamped report location under `logs/knowledge-update`.

The wrapper uses `runtime\python-mcp\Scripts\python.exe`, resolves all paths beneath its own repository root, and exits non-zero if a required stage fails.

## Components

### Source updater

Refactor `scripts/update_knowledge.py` only enough to make its result truthful and safe:

- return structured per-repository status containing branch, previous commit, resulting commit, update outcome, and error
- distinguish a successful update from a retained stale checkout
- download into temporary files and use atomic replacement
- defer removal of generated legacy mirrors until source acquisition succeeds
- write `knowledge_manifest.json` atomically only after the source stage completes
- preserve current zero-copy behavior

Repository failures are recorded and make the source stage fail, but existing working trees remain untouched and available for rollback or offline rebuilding.

### Mapping crosswalk builder

Add `scripts/build_mapping_corpus.py` as the owned implementation for the existing schema-v3 database. It discovers canonical inputs from:

- Mojang `client_mappings.txt` and optional `server_mappings.txt`
- MCPConfig TSRG/mapping files
- MCP stable CSV files where available

Each source record stores its physical path, Minecraft version, namespace pair, size, modification time, and SHA-256. Unchanged sources are skipped. Changed sources are reparsed into a new versioned SQLite database built beside the active database. Only after schema checks and a data probe pass does the builder atomically replace `_ACTIVE_DB.txt`. The prior database remains available.

The database exposes the tables already consumed by `knowledge_mcp.py`: `sources` and `symbols`, with schema version 3 and namespace values limited to `obfuscated`, `srg`, `mcp`, and `official`.

### General knowledge index

Continue using `scripts/index_knowledge.py`. It scans the canonical data tree, skips unchanged files using metadata and hashes, creates a versioned database for schema migrations, and changes the active pointer only after the new database is complete.

### Validation and reporting

Continue using `scripts/validate_knowledge_index.py`, extending it only where necessary to validate:

- source manifest completion
- readable mapping and knowledge databases
- active-pointer targets
- expected namespaces and minimum source coverage
- canonical paths that exist
- absence of partial download files

The PowerShell wrapper writes one JSON report even on failure. It includes start/end timestamps, duration, arguments, stage results, repository outcomes, active database paths, validation output, and a final status. Human-readable console output summarizes the same stages.

## Data Flow

1. Acquire an exclusive update lock under `state` to prevent overlapping runs.
2. Refresh or inspect canonical source inputs.
3. Build and validate a candidate mapping database, then switch its active pointer.
4. Incrementally update or migrate the general knowledge database.
5. Run end-to-end validation.
6. Write the final report and release the lock.

If stages 2 through 4 fail, later dependent stages do not run. Validation still performs safe checks against the last active databases and the report identifies the failed stage.

## Failure and Recovery Rules

- Never delete an active database during refresh.
- Never switch an active pointer to an unvalidated database.
- Never replace a verified download with a partial file.
- Preserve the last known-good Git checkout when fetch or fast-forward fails.
- Treat a retained stale checkout as a reported failure, not a successful update.
- Refuse overlapping runs with a clear error and report.
- Remove abandoned temporary files only when they are recognized updater-owned files.
- Do not modify Windows Task Scheduler.

## Testing

Use Python's standard `unittest` framework so tests require no new package installation.

Tests use temporary repositories and data directories and cover:

- unchanged Git source, successful fast-forward, and failed update status
- atomic JSON and active-pointer replacement
- Mojang download cache and partial-file behavior
- mapping parsers for Mojang ProGuard mappings, TSRG/TSRG2, and MCP CSVs
- incremental mapping rebuild with unchanged and removed sources
- failed candidate validation preserving the old active database
- wrapper argument construction, stage stop behavior, lock handling, exit codes, and report creation

A final offline integration test builds small fixture mapping and knowledge databases, switches their pointers, and runs validation without contacting external services.

## Documentation

Update `README.md` with:

- the one-command refresh workflow
- default client-only, snapshots-enabled behavior
- release-only and server switches
- offline derived-index rebuild
- report location and failure interpretation
- a statement that no scheduled task is installed

## Acceptance Criteria

- `.\Update-GokuKnowledge.ps1` performs the complete ordered pipeline.
- A failed required stage produces a non-zero exit code and a JSON report.
- Existing active databases remain usable after any simulated failure.
- A successful fixture run produces searchable official, SRG, and MCP mapping edges.
- A second unchanged fixture run reparses zero mapping sources.
- The source manifest distinguishes updated, unchanged, and retained-stale repositories.
- All unit and offline integration tests pass.
- Existing `validate_knowledge_index.py` checks pass against the live corpus after a real run.
- No scheduled task is created or changed.
