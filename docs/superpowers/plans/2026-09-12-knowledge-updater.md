# Complete Minecraft Knowledge Updater Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver one explicit PowerShell command that safely updates Minecraft knowledge sources, incrementally rebuilds the mapping and text indexes, validates them, and reports every outcome.

**Architecture:** Python modules own source acquisition and mapping-corpus generation; the existing Python indexer and validator remain the derived-data authorities. A thin PowerShell wrapper serializes stages, enforces a single-run lock, captures structured results, and never replaces active database pointers until candidate validation succeeds.

**Tech Stack:** PowerShell 7/Windows PowerShell 5.1-compatible script, Python 3 standard library, SQLite 3, Git CLI, `unittest`.

**Spec:** `docs/superpowers/specs/2026-09-12-knowledge-updater-design.md`

## Global Constraints

- The workflow is manually invoked; it must not create or modify Windows scheduled tasks.
- Mojang snapshots are enabled by default; `-ReleaseOnly` disables them.
- Client and server mapping files are enabled by default; `-IncludeServerJar` additionally enables the dedicated-server JAR.
- Existing active databases and Git checkouts remain usable after any failed stage.
- No new Python packages may be required.
- Canonical data stays under `C:\GokuCodexAI\Data` in zero-copy form.
- Exact-version trees are audited and indexed but not automatically branch-created or switched.

---

### Task 1: Source updater safety and truthful status

**Files:**
- Modify: `scripts/update_knowledge.py`
- Create: `tests/test_update_knowledge.py`

**Interfaces:**
- Produces: `atomic_write_json(path: Path, data: Any) -> bool`
- Produces: `update_git_repo(name: str, url: str, upstream: Path, quiet: bool) -> dict[str, Any]`
- Produces: source-stage manifest fields `status`, `previous_commit`, `resulting_commit`, `branch`, and `error` for every repository.
- Produces: CLI option `--release-only`; snapshots are selected unless this flag is present.

- [ ] **Step 1: Write failing tests for atomic JSON and repository outcomes**

```python
class SourceUpdaterTests(unittest.TestCase):
    def test_atomic_write_json_leaves_no_partial_file(self):
        changed = updater.atomic_write_json(self.root / "manifest.json", {"ok": True})
        self.assertTrue(changed)
        self.assertEqual(json.loads((self.root / "manifest.json").read_text()), {"ok": True})
        self.assertFalse((self.root / "manifest.json.part").exists())

    def test_failed_git_update_is_reported_as_retained_stale(self):
        with mock.patch.object(updater, "run", side_effect=RuntimeError("offline")):
            result = updater.update_git_repo("repo", "https://invalid", self.existing_repo, True)
        self.assertEqual(result["status"], "retained_stale")
        self.assertEqual(result["error"], "offline")

    def test_snapshots_default_and_release_only_opt_out(self):
        self.assertTrue(updater.should_include_snapshots(release_only=False))
        self.assertFalse(updater.should_include_snapshots(release_only=True))
```

- [ ] **Step 2: Run the focused tests and verify they fail because the new interfaces do not exist**

Run: `runtime\python-mcp\Scripts\python.exe -m unittest tests.test_update_knowledge -v`

Expected: failures naming `atomic_write_json`, structured repository status, and `should_include_snapshots`.

- [ ] **Step 3: Implement atomic writes, structured Git outcomes, deferred cleanup, and snapshot defaults**

Use a sibling `.part` file followed by `os.replace`; query Git branch/commit before and after fetch/pull; return `updated`, `unchanged`, or `retained_stale`; move `remove_generated_duplicate_mirrors` after successful source acquisition; write the manifest only after all source work and include a top-level `status`.

- [ ] **Step 4: Run the source updater tests and the CLI help probe**

Run:

```powershell
runtime\python-mcp\Scripts\python.exe -m unittest tests.test_update_knowledge -v
runtime\python-mcp\Scripts\python.exe scripts\update_knowledge.py --help
```

Expected: all tests pass; help shows `--release-only` and no `--include-snapshots` option.

- [ ] **Step 5: Commit the source updater unit**

```powershell
git add scripts/update_knowledge.py tests/test_update_knowledge.py
git commit -m "feat: make knowledge source updates recoverable"
```

### Task 2: Incremental mapping-corpus builder

**Files:**
- Create: `scripts/build_mapping_corpus.py`
- Create: `tests/test_build_mapping_corpus.py`

**Interfaces:**
- Produces: `MappingRecord` values with version, namespace pair, kind, owners, names, and signature.
- Produces: `discover_sources(data_root: Path) -> list[SourceInput]`
- Produces: `parse_source(source: SourceInput) -> Iterator[MappingRecord]`
- Produces: `build_corpus(data_root: Path, output_root: Path) -> dict[str, Any]`
- Produces: schema-v3 `sources` and `symbols` tables consumed unchanged by `knowledge_mcp.py`.

- [ ] **Step 1: Write failing parser tests using minimal real mapping fixtures**

```python
def test_parses_mojang_method(self):
    rows = list(parse_mojang(["net.minecraft.C -> a.b.C:", "    1:1:void tick(int) -> a"]))
    self.assertEqual((rows[1].namespace_from, rows[1].namespace_to), ("official", "obfuscated"))
    self.assertEqual((rows[1].name_from, rows[1].name_to), ("tick", "a"))

def test_parses_tsrg2_method(self):
    rows = list(parse_tsrg2(["tsrg2 obf srg", "a net/minecraft/C", "\tb (I)V m_123_"]))
    self.assertEqual((rows[0].name_from, rows[0].name_to), ("b", "m_123_"))

def test_joins_mcp_csv_names(self):
    edges = list(parse_mcp_csv(["searge,name,side,desc", "m_123_,tick,2,"]))
    self.assertEqual((edges[0].namespace_from, edges[0].namespace_to), ("srg", "mcp"))
```

- [ ] **Step 2: Run parser tests and verify missing parser failures**

Run: `runtime\python-mcp\Scripts\python.exe -m unittest tests.test_build_mapping_corpus.MappingParserTests -v`

Expected: import failure for the not-yet-created builder module.

- [ ] **Step 3: Implement the three parsers and deterministic source discovery**

Normalize owners to slash-separated class names, preserve descriptors in `signature`, classify fields and methods, reject malformed rows with counted warnings, and sort discovered paths for reproducible builds.

- [ ] **Step 4: Run parser tests until green**

Run: `runtime\python-mcp\Scripts\python.exe -m unittest tests.test_build_mapping_corpus.MappingParserTests -v`

Expected: all parser tests pass.

- [ ] **Step 5: Write failing transactional and incremental builder tests**

```python
def test_second_build_reparses_zero_sources(self):
    first = build_corpus(self.data, self.out)
    second = build_corpus(self.data, self.out)
    self.assertEqual(first["changed_sources_this_run"], 1)
    self.assertEqual(second["changed_sources_this_run"], 0)

def test_invalid_candidate_preserves_active_pointer(self):
    old = self.write_active_fixture()
    with mock.patch.object(builder, "validate_candidate", return_value=False):
        with self.assertRaises(RuntimeError):
            build_corpus(self.data, self.out)
    self.assertEqual((self.out / "_ACTIVE_DB.txt").read_text().strip(), old.name)

def test_removed_source_is_absent_from_new_database(self):
    build_corpus(self.data, self.out)
    self.fixture.unlink()
    result = build_corpus(self.data, self.out)
    self.assertEqual(result["removed_sources_this_run"], 1)
```

- [ ] **Step 6: Run builder tests and verify expected failures**

Run: `runtime\python-mcp\Scripts\python.exe -m unittest tests.test_build_mapping_corpus.MappingBuilderTests -v`

Expected: failures because `build_corpus` and candidate switching are absent.

- [ ] **Step 7: Implement versioned candidate cloning/rebuild and atomic pointer switch**

Create schema v3 exactly matching the live `sources` and `symbols` columns and indexes. Copy unchanged source rows and symbols from the prior active database, parse changed inputs, omit removed inputs, run `PRAGMA foreign_key_check`, verify namespaces and non-empty tables, then atomically switch `_ACTIVE_DB.txt` and write `_STATUS.json`.

- [ ] **Step 8: Run all mapping-builder tests**

Run: `runtime\python-mcp\Scripts\python.exe -m unittest tests.test_build_mapping_corpus -v`

Expected: all tests pass, including zero changed sources on the second build.

- [ ] **Step 9: Commit the mapping builder unit**

```powershell
git add scripts/build_mapping_corpus.py tests/test_build_mapping_corpus.py
git commit -m "feat: add incremental mapping corpus builder"
```

### Task 3: End-to-end PowerShell orchestrator

**Files:**
- Create: `Update-GokuKnowledge.ps1`
- Create: `tests/Test-UpdateGokuKnowledge.ps1`

**Interfaces:**
- Consumes: the three Python CLIs and their exit codes/status JSON files.
- Produces: parameters `ReleaseOnly`, `IncludeServerJar`, `SkipSourceUpdate`, and `ReportPath`.
- Produces: JSON report schema `goku-knowledge-update-v1` with `status`, timestamps, arguments, stage array, active database paths, and validation result.

- [ ] **Step 1: Write a failing PowerShell harness for stage order and failure stops**

```powershell
$result = & $script -Root $fixture -Python $fakePython -ReportPath $report
Assert-Equal @('sources','mappings','knowledge-index','validation') (Read-StageLog $fixture)
Assert-Equal 0 $LASTEXITCODE

$env:GOKU_TEST_FAIL_STAGE = 'mappings'
& $script -Root $fixture -Python $fakePython -ReportPath $report
Assert-True ($LASTEXITCODE -ne 0)
Assert-Equal @('sources','mappings','validation') (Read-StageLog $fixture)
Assert-Equal 'failed' ((Get-Content $report -Raw | ConvertFrom-Json).status)
```

- [ ] **Step 2: Run the harness and verify it fails because the wrapper is absent**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File tests\Test-UpdateGokuKnowledge.ps1`

Expected: failure locating `Update-GokuKnowledge.ps1`.

- [ ] **Step 3: Implement wrapper, exclusive lock, stage runner, and always-written report**

Use an exclusive `FileStream` for `state\knowledge-update.lock`; invoke `runtime\python-mcp\Scripts\python.exe`; translate `-ReleaseOnly` to `--release-only` and `-IncludeServerJar` to `--include-server-jar`; run validation after failures against retained active databases; release the lock in `finally`; serialize the report with `ConvertTo-Json -Depth 10` to a `.part` file and atomically move it into place.

- [ ] **Step 4: Run the PowerShell harness until green**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File tests\Test-UpdateGokuKnowledge.ps1`

Expected: all assertions pass for success, stage failure, and overlapping lock cases.

- [ ] **Step 5: Commit the orchestration unit**

```powershell
git add Update-GokuKnowledge.ps1 tests/Test-UpdateGokuKnowledge.ps1
git commit -m "feat: orchestrate complete knowledge refresh"
```

### Task 4: Validation, offline integration, and documentation

**Files:**
- Modify: `scripts/validate_knowledge_index.py`
- Create: `tests/test_knowledge_update_integration.py`
- Modify: `README.md`

**Interfaces:**
- Consumes: source manifest, active mapping pointer, active knowledge pointer, and mapping status.
- Produces: validation metrics for manifest completion, pointer targets, namespaces, source paths, and `.part` hygiene.

- [ ] **Step 1: Write failing validation and offline integration tests**

```python
def test_validator_rejects_partial_files(self):
    (self.data / "orphan.jar.part").write_bytes(b"partial")
    report = run_validator(self.station)
    self.assertFalse(report["ok"])
    self.assertIn("partial_files_absent", report["failures"])

def test_offline_pipeline_exposes_mapping_edges(self):
    build_corpus(self.data, self.mapping_root)
    build_knowledge_index(self.data, self.knowledge_db)
    report = run_validator(self.station)
    self.assertTrue(report["ok"])
    self.assertMapping("m_123_", "tick", "srg", "mcp")
```

- [ ] **Step 2: Run tests and verify the new validation assertions fail**

Run: `runtime\python-mcp\Scripts\python.exe -m unittest tests.test_knowledge_update_integration -v`

Expected: failure because partial-file and manifest-completion validation is absent.

- [ ] **Step 3: Add bounded validation checks and document the workflow**

Check pointer existence, source manifest status, canonical paths, namespaces, minimum mapping sources, and updater-owned `.part` files. Document `Update-GokuKnowledge.ps1`, default snapshots and dual mapping files, `-ReleaseOnly`, the optional server JAR, offline rebuild, reports, and the absence of scheduling.

- [ ] **Step 4: Run all automated tests**

Run:

```powershell
runtime\python-mcp\Scripts\python.exe -m unittest discover -s tests -p "test_*.py" -v
powershell -NoProfile -ExecutionPolicy Bypass -File tests\Test-UpdateGokuKnowledge.ps1
```

Expected: all tests pass with no warnings or tracebacks.

- [ ] **Step 5: Commit validation and documentation**

```powershell
git add scripts/validate_knowledge_index.py tests/test_knowledge_update_integration.py README.md
git commit -m "docs: validate and document knowledge refresh"
```

### Task 5: Live no-source-change verification and guarded real refresh

**Files:**
- Modify only if a test exposes a defect in files from Tasks 1–4.
- Generate: `logs/knowledge-update/*.json` (ignored runtime report).

**Interfaces:**
- Consumes: completed wrapper and current canonical corpus.
- Produces: verified live report and active databases.

- [ ] **Step 1: Run an offline derived-data refresh against the live local sources**

Run: `.\Update-GokuKnowledge.ps1 -SkipSourceUpdate`

Expected: mapping and knowledge indexes complete, validation passes, and a JSON report records success without network access.

- [ ] **Step 2: Verify active database integrity and mapping behavior**

Run the validator with JSON output, then call the existing mapping lookup logic against one known official edge and the legacy `func_184185_a` SRG/MCP edge.

Expected: both active pointers resolve, SQLite integrity checks pass, and both lookups return deterministic results.

- [ ] **Step 3: Run the real default refresh**

Run: `.\Update-GokuKnowledge.ps1`

Expected: snapshots and both mapping files are included, the server JAR remains excluded, every repository reports `updated` or `unchanged`, derived indexes switch safely, and validation succeeds.

- [ ] **Step 4: Review the report and repository diff**

Confirm no scheduled task was created, no unrelated user changes were staged, no `.part` files remain, and the report agrees with active pointer/status files.

- [ ] **Step 5: Commit any test-proven corrections, then record final verification**

Stage only updater-owned source, test, and documentation files. Do not stage corpus databases, logs, unrelated modifications, or user work.
