# Codex-native GokuCodexAI Repair Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace every active Grok-dependent LegacyJavaConverter repair path with a native Codex-orchestrated GokuCodexAI workflow while preserving deterministic-first conversion, optional local workers, complete evidence, and separate build/runtime validation.

**Architecture:** `RobbieB1980/LegacyJavaConverter` remains the canonical converter and owns the versioned repair contract and workspace overlay. Failed outputs receive native `AGENTS.md`, `.agents/skills`, `.codex/config.toml`, and `CODEX_REPAIR_REQUEST.md`; `C:\GokuCodexAI` launches Codex as orchestrator and exposes KAT/Qwen only as bounded local workers. Implementation is split between an isolated converter worktree and a clean GokuCodexAI feature worktree so the existing dirty `C:\GokuCodexAI` checkout is preserved until tested changes are deliberately integrated.

**Tech Stack:** PowerShell 5.1/7, .NET 8 WinForms, WiX/setup project, Codex CLI, Codex `AGENTS.md`, repository skills under `.agents/skills`, project configuration under `.codex/config.toml`, Python MCP knowledge server, llama.cpp local workers, JavaParser AST worker, Gradle/NeoGradle, Java 25, NeoForge 26.2.

**Spec:** `docs/superpowers/specs/2026-09-21-codex-native-goku-repair-design.md`

## Global Constraints

- Keep `RobbieB1980/LegacyJavaConverter` as the canonical converter repository.
- Keep the target at NeoForge 26.2; do not ingest or retarget to NeoForge 26.3.
- Use `C:\GokuCodexAI` as the only active AI root.
- Codex is the repair orchestrator; KAT and Qwen are optional bounded local workers.
- No active path may depend on `grok.exe`, `grok-home`, `GROK_HOME`, Grok authentication, Grok services, `.grok/config.toml`, or `.grok/skills`.
- Preserve `C:\gokuai` and `C:\GokuCodexAI\projects\RMCodexMCConverter`; deletion or retirement is a separate decision.
- Preserve all pre-existing uncommitted changes in `C:\GokuCodexAI`; do not reset, stash, overwrite, or bulk-copy over them.
- Historical case names, changelog entries, and literal source paths containing “Grok” remain when they record provenance, but they cannot be active instructions.
- Use repository skills under `.agents/skills`, project MCP configuration under `.codex/config.toml`, and durable workflow rules in `AGENTS.md`.
- Keep the product baseline at 3.0.0 unless release policy is explicitly revised.
- A clean Gradle build is not proof of successful launch, content registration, or faithful gameplay behavior.

## Review Focus

- A failed output path containing spaces and apostrophes must launch Codex with the intact path and without command injection; Task 5 adds a launcher argument-capture test.
- A machine with Codex installed in a newer WindowsApps version must resolve it dynamically rather than using a versioned hard-coded path; Task 5 adds a resolver test with a fake command path.
- A stale or incomplete workspace overlay must stop before Codex opens and list the missing native files; Task 4 adds a missing-skill preflight test.
- A local worker that is missing, times out, or returns malformed JSON must leave the failed project unchanged and return control to Codex; Task 7 adds worker-contract fallback tests.
- A project that compiles but has missing resources or unresolved entity/AI behavior must remain incomplete; Task 8 adds independent status-gate assertions.

---

## File and responsibility map

### LegacyJavaConverter repository

- `lib/ConversionCore.ps1`: canonical repair-request generation and shared repair metadata.
- `Open-CodexRepairSession.ps1`: portable native launcher and preflight entry point.
- `Open-GrokRepairSession.ps1`: one-release deprecation wrapper only.
- `scripts/Sync-CodexConverterWorkspace.ps1`: deterministic native overlay sync.
- `scripts/Sync-GokuaiConverterWorkspace.ps1`: deprecated forwarding wrapper.
- `gokuai-workspace-overlay/AGENTS.md`: repair-workspace orchestration rules.
- `gokuai-workspace-overlay/.agents/skills/`: canonical repository-scoped migration skills.
- `gokuai-workspace-overlay/.codex/config.toml`: template MCP project configuration.
- `gokuai-workspace-overlay/tools/`: repair and validation tools installed into failed outputs.
- `src/RB.LegacyJavaConverter/MainForm.cs`: non-technical GUI repair action and process launch.
- `src/RB.LegacyJavaConverter/RB.LegacyJavaConverter.csproj`: application tool packaging.
- `eng/portable-manifest.json`: portable release inventory.
- `scripts/Build-Release.ps1`: release build and workspace sync.
- `scripts/Publish-GitHubRelease.ps1`: native release notes.
- `tests/Run-CodexHandoffTests.ps1`: native request, sync, and launcher contract tests.
- `tests/Run-GokuHandoffTests.ps1`: compatibility entry forwarding to the native test suite.
- `tests/Run-RegressionTests.ps1`: global packaging and active-dependency assertions.

### GokuCodexAI repository

- `AGENTS.md`: Codex-first orchestration authority and escalation order.
- `.codex/config.toml`: local Minecraft knowledge MCP configuration.
- `Open-CodexRepairSession.ps1`: live Codex launcher used by converter handoff.
- `Open-KATRepairSession.ps1`: bounded KAT worker adapter.
- `Watch-CodexGuidance.ps1`: Codex session completion/result watcher.
- `Watch-KATRepairSession.ps1`: local worker timeout/result watcher.
- `scripts/Sync-LegacyConverterWorkspace.ps1`: installs the canonical native overlay.
- `Validate-GokuAI.ps1`: verifies native Codex, MCP, local workers, paths, and absence of active Grok dependencies.
- `README.md`: user-facing control-plane and repair-flow documentation.
- `tests/Run-CodexControlPlaneTests.ps1`: deterministic control-plane tests without opening interactive sessions.

## Task 1: Establish isolated worktrees and executable legacy-reference classification

**Files:**
- Create: `tests/fixtures/active-grok-reference-allowlist.txt`
- Create: `tests/Run-CodexNativeAuditTests.ps1`
- Modify: `.gitignore`

**Interfaces:**
- Consumes: clean LegacyJavaConverter `main` at specification commit `5332802`; dirty live GokuCodexAI checkout.
- Produces: converter worktree branch `feat/codex-native-goku-repair`, GokuCodexAI worktree branch `feat/codex-native-repair-control-plane`, and `Run-CodexNativeAuditTests.ps1 -ProjectRoot <path>` returning exit code 0 only when no unclassified active Grok dependency exists.

- [ ] **Step 1: Create the converter worktree with the worktree skill**

Use `superpowers:using-git-worktrees` and create a sibling worktree for `C:\gokuai\projects\_upstream\LegacyJavaConverter` on branch `feat/codex-native-goku-repair`. Verify `git status --short` is empty before editing.

- [ ] **Step 2: Record the live GokuCodexAI state without modifying it**

Run:

```powershell
git -C C:\GokuCodexAI status --short --branch
git -C C:\GokuCodexAI diff --name-status
git -C C:\GokuCodexAI ls-files --others --exclude-standard
```

Copy the displayed file lists into the execution log. Do not run reset, stash, clean, checkout, or restore.

- [ ] **Step 3: Create a clean GokuCodexAI feature worktree**

Use `superpowers:using-git-worktrees` against `C:\GokuCodexAI` and create branch `feat/codex-native-repair-control-plane` from its current `HEAD`. The live dirty tree remains the comparison source; only deliberately reviewed content is ported to the clean worktree.

- [ ] **Step 4: Write the failing active-reference audit**

Create `tests/Run-CodexNativeAuditTests.ps1` with these inputs and classifications:

```powershell
[CmdletBinding()]
param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
$activeRoots = @('src','lib','scripts','eng','gokuai-workspace-overlay','tests')
$activeFiles = @(
    'Open-GrokRepairSession.ps1',
    'Open-CodexRepairSession.ps1',
    'Convert-Forge1201-ToNeoForge262.ps1',
    'Lint-MigrationSkills.ps1'
)
$forbidden = 'grok\.exe|grok-home|GROK_HOME|grok mcp|\.grok[\\/](config\.toml|skills|agents|rules|workflows)'
$allowlistPath = Join-Path $PSScriptRoot 'fixtures\active-grok-reference-allowlist.txt'
$allowlist = if (Test-Path $allowlistPath) { @(Get-Content $allowlistPath | Where-Object { $_ -and -not $_.StartsWith('#') }) } else { @() }
$hits = foreach ($root in $activeRoots) {
    $path = Join-Path $ProjectRoot $root
    if (Test-Path $path) {
        Get-ChildItem $path -Recurse -File | Select-String -Pattern $forbidden | ForEach-Object {
            '{0}:{1}:{2}' -f $_.Path.Substring($ProjectRoot.Length + 1),$_.LineNumber,$_.Line.Trim()
        }
    }
}
$hits += foreach ($relative in $activeFiles) {
    $path = Join-Path $ProjectRoot $relative
    if (Test-Path $path -PathType Leaf) {
        Select-String -LiteralPath $path -Pattern $forbidden | ForEach-Object {
            '{0}:{1}:{2}' -f $relative,$_.LineNumber,$_.Line.Trim()
        }
    }
}
$unexpected = @($hits | Where-Object { $line=$_; -not ($allowlist | Where-Object { $line -like $_ }) })
if ($unexpected.Count) { $unexpected | ForEach-Object { Write-Error "Active Grok dependency: $_" }; exit 1 }
Write-Host 'PASS: no unclassified active Grok dependencies.'
```

Seed `active-grok-reference-allowlist.txt` with comments only; historical docs are outside the scanned active roots.

- [ ] **Step 5: Run the audit and verify it fails on current active dependencies**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-CodexNativeAuditTests.ps1
```

Expected: FAIL with hits in the current launcher, sync, overlay, packaging, tests, or GUI-adjacent active files.

- [ ] **Step 6: Ignore only generated test worktrees/artifacts**

Add the exact execution-time disposable fixture directory used by the tests to `.gitignore`; do not add broad `work/`, repository, or user-directory ignores.

- [ ] **Step 7: Commit the audit baseline**

```powershell
git add .gitignore tests/fixtures/active-grok-reference-allowlist.txt tests/Run-CodexNativeAuditTests.ps1
git commit -m "test: audit active Grok dependencies"
```

## Task 2: Introduce the native repair-request API with compatibility aliases

**Files:**
- Modify: `lib/ConversionCore.ps1:1321-1415`
- Modify: `tests/Run-GokuHandoffTests.ps1`
- Create: `tests/Run-CodexHandoffTests.ps1`

**Interfaces:**
- Consumes: `Write-MigrationEvidencePacket`, destination Java major, failed output path, and target Minecraft/NeoForge profile.
- Produces: `Get-CodexRepairRequestBody([string]$FailedOutput,[int]$DestinationJavaMajor,[string]$TargetMinecraft) -> string` and `Write-CodexRepairRequest(...) -> absolute CODEX_REPAIR_REQUEST.md path`. Deprecated `Get-GrokRepairPromptBody` and `Write-GrokRepairPrompt` forward to the native functions for one compatibility release.

- [ ] **Step 1: Add failing request-generation assertions**

Create `tests/Run-CodexHandoffTests.ps1` and dot-source `lib/ConversionCore.ps1`. Add assertions that the native body contains all of these exact concepts:

```powershell
$body = Get-CodexRepairRequestBody -FailedOutput $failed -DestinationJavaMajor 25 -TargetMinecraft '26.2'
Assert-Contains $body 'Codex is the repair orchestrator' 'orchestrator authority'
Assert-Contains $body 'legacy-java-converter-vnext' 'native vNext skill'
Assert-Contains $body '.agents/skills' 'native repository skill location'
Assert-Contains $body '.codex/config.toml' 'native MCP configuration'
Assert-Contains $body 'Solutions Index' 'known solution stage'
Assert-Contains $body 'Build-WithDestinationJava.ps1' 'destination Java build'
Assert-Contains $body 'runtime' 'runtime validation remains separate'
Assert-NotContains $body 'GROK_HOME' 'no Grok environment'
Assert-NotContains $body '.grok/' 'no Grok project configuration'
$request = Write-CodexRepairRequest -FailedOutput $failed -DestinationJavaMajor 25 -TargetMinecraft '26.2'
Assert-Equal (Split-Path -Leaf $request) 'CODEX_REPAIR_REQUEST.md' 'native request filename'
```

Implement local `Assert-Contains`, `Assert-NotContains`, and `Assert-Equal` helpers that throw with the supplied label.

- [ ] **Step 2: Run the native test and verify the API is missing**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-CodexHandoffTests.ps1
```

Expected: FAIL because `Get-CodexRepairRequestBody` is not defined.

- [ ] **Step 3: Implement the native API**

Rename the canonical functions and change the generated file to `CODEX_REPAIR_REQUEST.md`. The body must order work as deterministic transforms, Solutions Index/262r, AST repair, preservation audit, destination-Java build, runtime/content/behavior validation, then unresolved Codex reasoning/local-worker delegation.

Use these signatures exactly:

```powershell
function Get-CodexRepairRequestBody {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$FailedOutput,
        [int]$DestinationJavaMajor = 25,
        [string]$TargetMinecraft = '26.2'
    )
    # Return one bounded Markdown request string.
}

function Write-CodexRepairRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$FailedOutput,
        [int]$DestinationJavaMajor = 25,
        [string]$TargetMinecraft = '26.2'
    )
    $path = Join-Path $FailedOutput 'CODEX_REPAIR_REQUEST.md'
    [IO.File]::WriteAllText($path, (Get-CodexRepairRequestBody @PSBoundParameters), [Text.UTF8Encoding]::new($false))
    return $path
}
```

- [ ] **Step 4: Add one-release compatibility aliases**

Keep the old function names as thin forwarding functions. They must emit `Write-Warning` and call only the native equivalents. They must not generate `GROK_REPAIR_PROMPT.md`.

- [ ] **Step 5: Convert the old handoff test into a forwarding entry**

Replace `tests/Run-GokuHandoffTests.ps1` test logic with a deprecation warning followed by invocation of `Run-CodexHandoffTests.ps1`, preserving its exit code.

- [ ] **Step 6: Run both entry points**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-CodexHandoffTests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-GokuHandoffTests.ps1
```

Expected: both PASS; the compatibility entry prints one deprecation warning.

- [ ] **Step 7: Commit the request contract**

```powershell
git add lib/ConversionCore.ps1 tests/Run-CodexHandoffTests.ps1 tests/Run-GokuHandoffTests.ps1
git commit -m "feat: generate native Codex repair requests"
```

## Task 3: Convert the packaged workspace overlay to native Codex discovery

**Files:**
- Rename: `gokuai-workspace-overlay/Agents.md` to `gokuai-workspace-overlay/AGENTS.md`
- Create: `gokuai-workspace-overlay/.codex/config.toml`
- Move and revise: `gokuai-workspace-overlay/.grok/skills/**` to `gokuai-workspace-overlay/.agents/skills/**`
- Convert relevant content from: `gokuai-workspace-overlay/.grok/agents/**`, `.grok/rules/**`, `.grok/workflows/**`
- Modify: `gokuai-workspace-overlay/README.md`
- Modify: `gokuai-workspace-overlay/tools/Lint-MigrationSkills.ps1`
- Modify: `Lint-MigrationSkills.ps1`

**Interfaces:**
- Consumes: existing Grok overlay instructions and the approved vNext skill content.
- Produces: `AGENTS.md`, `.agents/skills`, `.codex/config.toml`, and `Lint-MigrationSkills.ps1 -ProjectRoot <path>` validating native discovery and all skill references.

- [ ] **Step 1: Add failing native-layout assertions to the handoff test**

Assert these files exist and legacy discovery directories do not:

```powershell
$overlay = Join-Path $projectRoot 'gokuai-workspace-overlay'
Assert-Path (Join-Path $overlay 'AGENTS.md') 'native root guidance'
Assert-Path (Join-Path $overlay '.agents\skills\legacy-java-converter-vnext\SKILL.md') 'vNext skill'
Assert-Path (Join-Path $overlay '.agents\skills\repair-failed-262-output\SKILL.md') 'repair skill'
Assert-Path (Join-Path $overlay '.codex\config.toml') 'project MCP config'
Assert-False (Test-Path (Join-Path $overlay '.grok')) 'legacy overlay removed'
```

- [ ] **Step 2: Run the test and verify the native layout is absent**

Expected: FAIL on missing `AGENTS.md` or `.agents/skills`.

- [ ] **Step 3: Move skills and rewrite their internal references**

Use `git mv` for skill directories so history is retained. Update every active reference from `.grok/skills` to `.agents/skills`, and replace hosted-Grok tool language with native file/MCP operations. Keep the `legacy-java-converter-vnext` skill's deterministic-first, preservation, validation, and escalation contracts intact.

- [ ] **Step 4: Fold rules, agents, and workflow behavior into native surfaces**

Put always-on ordering and safety rules in root `AGENTS.md`. Put task-specific procedures and templates in the matching skill. Convert worker role descriptions into `.gokuai` issue-packet references used by the local-worker adapters. Do not create fictional Codex agent files that Codex will not discover.

- [ ] **Step 5: Add the MCP template**

Create `gokuai-workspace-overlay/.codex/config.toml` with project-relative placeholders consumed by sync:

```toml
approval_policy = "on-request"
model_reasoning_summary = "auto"

[mcp_servers.minecraft-knowledge]
command = "__GOKU_PYTHON__"
args = ["__KNOWLEDGE_MCP__", "--db", "__KNOWLEDGE_DB__", "--root", "__KNOWLEDGE_ROOT__"]
cwd = "__GOKU_ROOT__"
required = true
startup_timeout_sec = 60
tool_timeout_sec = 120
```

- [ ] **Step 6: Rewrite both lint entry points**

Validate `SKILL.md` front matter (`name`, `description`), referenced relative files, required vNext sections, absence of active `.grok` paths, and absence of unresolved `__...__` placeholders after synchronization. The root linter and overlay tool must share the same checks by making the overlay copy invoke the packaged root implementation rather than maintaining divergent logic.

- [ ] **Step 7: Run native handoff and lint tests**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Lint-MigrationSkills.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-CodexHandoffTests.ps1
```

Expected: PASS with no `.grok` discovery dependency.

- [ ] **Step 8: Commit the native overlay**

```powershell
git add gokuai-workspace-overlay Lint-MigrationSkills.ps1 tests/Run-CodexHandoffTests.ps1
git commit -m "feat: package native Codex repair workspace"
```

## Task 4: Replace workspace synchronization with an idempotent native preflight

**Files:**
- Create: `scripts/Sync-CodexConverterWorkspace.ps1`
- Modify: `scripts/Sync-GokuaiConverterWorkspace.ps1`
- Modify: `tests/Run-CodexHandoffTests.ps1`

**Interfaces:**
- Consumes: `-Workspace`, optional `-GokuRoot`, optional `-SkillsOnly`, and the versioned overlay.
- Produces: synchronized native workspace plus a `[pscustomobject]` containing `Workspace`, `OverlaySource`, `FilesVerified`, `SkillVersion`, and `Ready`; compatibility sync forwards to it.

- [ ] **Step 1: Add a disposable-workspace sync test**

Create a fixture under the test artifact directory, place a sentinel `src/main/java/UserFile.java` in it, run the new sync script twice, then assert:

```powershell
Assert-Path (Join-Path $workspace 'AGENTS.md') 'guidance synced'
Assert-Path (Join-Path $workspace '.agents\skills\legacy-java-converter-vnext\SKILL.md') 'skill synced'
Assert-Path (Join-Path $workspace '.codex\config.toml') 'MCP config synced'
Assert-Path (Join-Path $workspace 'src\main\java\UserFile.java') 'user file preserved'
Assert-FileDoesNotContain (Join-Path $workspace '.codex\config.toml') '__GOKU_' 'MCP placeholders resolved'
Assert-FileDoesNotContain (Join-Path $workspace '.codex\config.toml') '__KNOWLEDGE_' 'knowledge placeholders resolved'
Assert-False (Test-Path (Join-Path $workspace '.grok')) 'legacy discovery not created'
```

Hash all synchronized files after each run and assert the hashes are identical.

- [ ] **Step 2: Add the stale-overlay failure test**

Copy the overlay into a disposable fixture, remove `.agents/skills/legacy-java-converter-vnext/SKILL.md`, invoke sync with `-OverlayRoot` pointing to that fixture, and assert non-zero exit plus an error containing the missing relative path. This covers the Review Focus stale-overlay case.

- [ ] **Step 3: Run tests and verify the new script is missing**

Expected: FAIL because `Sync-CodexConverterWorkspace.ps1` does not exist.

- [ ] **Step 4: Implement native synchronization**

Use explicit source/target paths, copy only the native overlay and required tools, replace MCP placeholders with escaped absolute `C:\GokuCodexAI` paths, preserve all other workspace files, and verify this required list after copying:

```powershell
$required = @(
  'AGENTS.md',
  '.codex\config.toml',
  '.agents\skills\legacy-java-converter-vnext\SKILL.md',
  '.agents\skills\repair-failed-262-output\SKILL.md',
  'tools\Build-WithDestinationJava.ps1',
  'tools\Lint-MigrationSkills.ps1'
)
```

Support `-PrepareOnly` test behavior by returning readiness data without launching anything.

- [ ] **Step 5: Make the old sync script a forwarding wrapper**

It prints one deprecation warning and invokes `Sync-CodexConverterWorkspace.ps1` with the same bound arguments. Remove all `.grok` copying and fallback logic.

- [ ] **Step 6: Run handoff, idempotence, and active-reference tests**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-CodexHandoffTests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-CodexNativeAuditTests.ps1
```

Expected: handoff PASS; audit may still fail only on later GUI/packaging/launcher work.

- [ ] **Step 7: Commit synchronization**

```powershell
git add scripts/Sync-CodexConverterWorkspace.ps1 scripts/Sync-GokuaiConverterWorkspace.ps1 tests/Run-CodexHandoffTests.ps1
git commit -m "feat: synchronize native Codex repair workspaces"
```

## Task 5: Add the portable Codex launcher and migrate the GUI repair action

**Files:**
- Create: `Open-CodexRepairSession.ps1`
- Replace: `Open-GrokRepairSession.ps1` with forwarding wrapper
- Modify: `src/RB.LegacyJavaConverter/MainForm.cs:34,219-232,326,598,616,863-957`
- Modify: `Convert-Forge1201-ToNeoForge262.ps1:4490-4510`
- Modify: `tests/Run-CodexHandoffTests.ps1`

**Interfaces:**
- Consumes: `Open-CodexRepairSession.ps1 -FailedOutput <path> [-GokuRoot C:\GokuCodexAI] [-PrepareOnly] [-CodexPath <test path>]`.
- Produces: preflight result in prepare-only mode or one interactive Codex process with intact argument boundaries; GUI method `LaunchCodexRepairSession(bool offerPrompt)`.

- [ ] **Step 1: Add a launcher argument-capture test**

Create a failed-output fixture named `Mod's Failed Output 26.2`, generate `CODEX_REPAIR_REQUEST.md`, and pass a fake `codex.cmd` through `-CodexPath`. The fake records each received argument on a separate line. Assert `-C` is followed by the exact failed-output path, `--add-dir` is followed by the intended converter/Goku root, and no argument contains `grok`, `GROK_HOME`, or a split fragment of the path.

- [ ] **Step 2: Add dynamic resolution and preflight error tests**

With `-CodexPath` supplied, assert the launcher uses it. Without it and with `Get-Command codex` mocked unavailable in the test subprocess, assert the message is `Codex CLI could not be located. Open the Codex desktop app once, then retry Repair with GokuCodexAI.` Do not assert any fixed WindowsApps version.

- [ ] **Step 3: Run tests and verify the launcher is missing**

Expected: FAIL because `Open-CodexRepairSession.ps1` does not exist.

- [ ] **Step 4: Implement launcher preflight and argument-safe launch**

Resolve paths with `Resolve-Path -LiteralPath`, invoke native sync, call `Write-CodexRepairRequest`, validate required evidence, locate Codex by explicit test path then `Get-Command` then wildcard WindowsApps discovery, and build a PowerShell argument array rather than a concatenated command string. `-PrepareOnly` returns after validation and prints a machine-readable JSON readiness object.

- [ ] **Step 5: Convert the old launcher into a deprecation wrapper**

The wrapper accepts the old parameters, prints `Open-GrokRepairSession.ps1 is deprecated; using Open-CodexRepairSession.ps1.`, and forwards to the native launcher. It must contain none of the forbidden runtime strings.

- [ ] **Step 6: Rename the GUI symbols and user-facing text**

Use `_btnRepairGokuCodexAI`, button label `Repair with GokuCodexAI`, `LaunchCodexRepairSession`, and `BuildCodexRepairRequest`. Resolve the packaged `tools\Open-CodexRepairSession.ps1` first and the repository-root script during development. Dialog titles and logs must use `Repair with GokuCodexAI` and explain that deterministic/known-solution stages were exhausted.

- [ ] **Step 7: Update the command-line conversion failure path**

Replace `Write-GrokRepairPrompt` calls with `Write-CodexRepairRequest` and log the native request filename. Do not auto-launch Codex when `-Compile` fails unless the existing explicit launch option/GUI path requests it.

- [ ] **Step 8: Run launcher, handoff, compile, and audit tests**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-CodexHandoffTests.ps1
dotnet build .\src\RB.LegacyJavaConverter\RB.LegacyJavaConverter.csproj -c Release
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-CodexNativeAuditTests.ps1
```

Expected: handoff and build PASS; audit failures are limited to packaging/docs handled next.

- [ ] **Step 9: Commit launcher and GUI migration**

```powershell
git add Open-CodexRepairSession.ps1 Open-GrokRepairSession.ps1 Convert-Forge1201-ToNeoForge262.ps1 lib/ConversionCore.ps1 src/RB.LegacyJavaConverter/MainForm.cs tests/Run-CodexHandoffTests.ps1
git commit -m "feat: launch failed repairs in GokuCodexAI"
```

## Task 6: Update packaging, release automation, and active converter documentation

**Files:**
- Modify: `src/RB.LegacyJavaConverter/RB.LegacyJavaConverter.csproj`
- Modify: `src/RB.LegacyJavaConverter.Setup/RB.LegacyJavaConverter.Setup.csproj`
- Modify: `eng/portable-manifest.json`
- Modify: `scripts/Build-Release.ps1`
- Modify: `scripts/Publish-GitHubRelease.ps1`
- Modify: `tests/Run-RegressionTests.ps1`
- Modify: `README.md`
- Modify: `docs/USAGE.md`
- Modify: `docs/VNEXT-STATUS.md`
- Modify: `docs/DEPENDENCIES.md`
- Modify: `CHANGELOG.md` (new current entry only; retain history)

**Interfaces:**
- Consumes: native launcher, sync script, overlay, and 3.0.0 version metadata.
- Produces: installer/portable payload containing native repair files and current documentation with no active Grok instructions.

- [ ] **Step 1: Add failing release-inventory assertions**

In `Run-RegressionTests.ps1`, assert the app project and portable manifest include:

```text
Open-CodexRepairSession.ps1
scripts/Sync-CodexConverterWorkspace.ps1
gokuai-workspace-overlay/AGENTS.md
gokuai-workspace-overlay/.agents/skills/legacy-java-converter-vnext/SKILL.md
gokuai-workspace-overlay/.codex/config.toml
```

Assert `Open-GrokRepairSession.ps1` is present only when marked compatibility/deprecated and that release scripts do not describe `C:\gokuai` as the active root.

- [ ] **Step 2: Run regression tests and verify the native inventory is absent**

Expected: FAIL on the first missing native package entry.

- [ ] **Step 3: Update application and installer payloads**

Package `Open-CodexRepairSession.ps1` as `tools\Open-CodexRepairSession.ps1`, include the native sync script and overlay recursively, and retain the deprecated wrapper only for compatibility. Ensure hidden `.agents` and `.codex` directories are explicitly included rather than dropped by wildcard assumptions.

- [ ] **Step 4: Update release scripts and portable manifest**

Replace active Fix-in-Grok wording, old root paths, and old sync calls. Add an explicit post-package verification that opens the artifact inventory and fails if the native skill/config/request launcher is absent or if a Grok executable is included.

- [ ] **Step 5: Update current documentation without rewriting history**

Document the user flow as `Repair with GokuCodexAI`, Codex orchestration, optional local workers, native config locations, 26.2 target, and separate build/runtime outcomes. Add a 3.0.0 changelog item explaining the native migration; leave older dated Grok entries unchanged and label any cross-reference as historical.

- [ ] **Step 6: Run regression, handoff, audit, and build suites**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-RegressionTests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-CodexHandoffTests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-CodexNativeAuditTests.ps1
dotnet build .\RB.LegacyJavaConverter.sln -c Release
```

Expected: all PASS and build has zero errors.

- [ ] **Step 7: Commit packaging and docs**

```powershell
git add src eng scripts tests README.md docs CHANGELOG.md
git commit -m "build: package Codex-native repair workflow"
```

## Task 7: Align the GokuCodexAI control plane and bounded local workers

**Files (in the clean GokuCodexAI feature worktree):**
- Modify: `AGENTS.md`
- Verify/modify: `.codex/config.toml`
- Modify: `Open-CodexRepairSession.ps1`
- Modify: `Open-KATRepairSession.ps1`
- Modify: `Watch-CodexGuidance.ps1`
- Modify: `Watch-KATRepairSession.ps1`
- Modify: `scripts/Sync-LegacyConverterWorkspace.ps1`
- Modify: `Validate-GokuAI.ps1`
- Modify: `README.md`
- Create: `tests/Run-CodexControlPlaneTests.ps1`

**Interfaces:**
- Consumes: canonical converter overlay and `CODEX_REPAIR_REQUEST.md`; local knowledge MCP and optional worker runtime.
- Produces: `Open-CodexRepairSession.ps1 -ProjectPath <converter> -PromptFile <request> [-PrepareOnly]`, worker `request.json`/`result.json` contract, and a native control-plane validation command.

- [ ] **Step 1: Compare live dirty files before porting**

For every listed file, inspect `git -C C:\GokuCodexAI diff -- <file>` and the live file contents. Also compare the matching launcher, watcher, preparation, GUI, and conversion files under `projects/RMCodexMCConverter` so proven native behavior is deliberately ported rather than lost. Port only changes that implement the approved design or are prerequisites for current local models/knowledge. Record the source and rationale for each ported behavior and record excluded unrelated changes in the execution log. Do not copy either tree wholesale.

- [ ] **Step 2: Write failing control-plane authority tests**

Assert `AGENTS.md` contains `Codex is the repair orchestrator`, describes KAT/Qwen as optional bounded workers, and does not say GokuAI or a local model is the sole/persistent orchestrator. Assert the MCP root is `C:\GokuCodexAI`, sync uses `.agents/skills`, and no active control-plane file references `C:\gokuai`, `.grok`, or `GROK_HOME`.

- [ ] **Step 3: Add worker fallback fixtures**

The test invokes worker preparation against three fake outcomes: executable missing, watcher timeout, and malformed `result.json`. In every case assert a non-zero/recoverable worker status, no modifications under fixture `src`, preservation of the request packet, and a message containing `Codex will continue without the local worker.`

- [ ] **Step 4: Run tests and verify current authority/fallback failures**

Expected: FAIL because current `AGENTS.md` declares GokuAI the persistent local orchestrator and current sync still uses `.grok`.

- [ ] **Step 5: Rewrite authority and sync behavior**

Make Codex responsible for routing, evidence, worker selection, integration, validation, and promotion. Make `scripts/Sync-LegacyConverterWorkspace.ps1` call or consume the canonical converter native overlay, verify `AGENTS.md`, `.agents/skills`, and `.codex/config.toml`, and remove every `.grok` fallback.

- [ ] **Step 6: Harden the Codex launcher**

Accept the converter project and request path, validate both with literal paths, launch Codex in the failed output, add only required evidence directories, and support `-PrepareOnly`. Remove the current analysis-only/KAT-centric prompt; the opening prompt must tell Codex to execute the vNext skill and own the repair/verification cycle.

- [ ] **Step 7: Harden KAT/Qwen worker adapters and watchers**

Use a request schema with `issue_id`, `problem`, `acceptance_criteria`, `evidence_paths`, `failure_excerpt`, `validation_commands`, and `result_path`. Validate worker output has `status`, `diagnosis`, `files_changed`, `evidence_paths`, `validation`, `remaining_risks`, and `confidence`. On missing/timeout/malformed results, stop the worker, write a recoverable status, and return control without applying edits.

- [ ] **Step 8: Update validation and README**

`Validate-GokuAI.ps1` checks Codex discovery, project config, MCP command/database/root, local worker executables if configured, native skill discovery, canonical paths, and forbidden active Grok dependencies. README explains Codex-first flow and the optional local-worker boundary.

- [ ] **Step 9: Run the Goku control-plane tests**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-CodexControlPlaneTests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Validate-GokuAI.ps1
```

Expected: PASS without launching an interactive Codex or model process.

- [ ] **Step 10: Commit only reviewed feature-worktree files**

```powershell
git add AGENTS.md .codex/config.toml Open-CodexRepairSession.ps1 Open-KATRepairSession.ps1 Watch-CodexGuidance.ps1 Watch-KATRepairSession.ps1 scripts/Sync-LegacyConverterWorkspace.ps1 Validate-GokuAI.ps1 README.md tests/Run-CodexControlPlaneTests.ps1
git commit -m "feat: make Codex the Goku repair orchestrator"
```

## Task 8: Make preservation and validation outcomes independently machine-readable

**Files:**
- Modify: `lib/ConversionCore.ps1`
- Modify: `Convert-Forge1201-ToNeoForge262.ps1`
- Modify: `docs/schemas/conversion-manifest.schema.json`
- Modify: `tests/Run-ManifestTests.ps1`
- Modify: `tests/Run-RegressionTests.ps1`
- Modify: `gokuai-workspace-overlay/.agents/skills/legacy-java-converter-vnext/references/preservation-and-validation.md`

**Interfaces:**
- Consumes: source inventory, destination inventory, Gradle result, launch/registry/data/content/behavior evidence.
- Produces: manifest `validation` object with independent `build`, `launch`, `registryData`, `content`, and `behavior` states plus `preservation` findings for assets/models/items/entities/aiBehavior.

- [ ] **Step 1: Add failing manifest assertions for a compile-green but incomplete fixture**

Add a fixture where build status is `passed`, resources are missing, and entity AI is `not_tested`. Assert overall conversion status is not `complete`:

```powershell
Assert-Equal $manifest.validation.build.status 'passed' 'build gate'
Assert-Equal $manifest.validation.content.status 'failed' 'content gate'
Assert-Equal $manifest.validation.behavior.status 'not_tested' 'behavior gate'
Assert-Equal $manifest.status 'repair_required' 'overall status remains incomplete'
```

- [ ] **Step 2: Run manifest tests and verify the independent structure is missing**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-ManifestTests.ps1
```

Expected: FAIL on missing `validation.content` or `preservation.aiBehavior`.

- [ ] **Step 3: Extend the manifest schema**

Define each gate as an object with required `status` (`passed`, `failed`, `not_tested`, `not_applicable`), `evidence` array, and `notes` array. Require preservation categories `assets`, `models`, `items`, `entities`, and `aiBehavior`, each with source count, destination count, missing entries, and evidence paths.

- [ ] **Step 4: Populate independent outcomes in converter logic**

Build success sets only `validation.build`. File/inventory reconciliation sets content/preservation evidence but cannot set launch or behavior to passed. Runtime results are imported only from explicit validation evidence files. Overall status is `complete` only when all applicable gates pass and no required preservation item is missing.

- [ ] **Step 5: Update skill instructions and repair request summary**

Require Codex to report and update each gate separately. Missing runtime access remains `not_tested`, never inferred as passed.

- [ ] **Step 6: Run manifest, regression, and handoff tests**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-ManifestTests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-RegressionTests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-CodexHandoffTests.ps1
```

Expected: all PASS, including the compile-green/incomplete fixture.

- [ ] **Step 7: Commit independent validation gates**

```powershell
git add lib/ConversionCore.ps1 Convert-Forge1201-ToNeoForge262.ps1 docs/schemas/conversion-manifest.schema.json tests gokuai-workspace-overlay/.agents/skills/legacy-java-converter-vnext/references/preservation-and-validation.md
git commit -m "feat: separate build and runtime conversion validation"
```

## Task 9: Make Solutions Index lookup and repair promotion executable

**Files:**
- Modify: `lib/ConversionCore.ps1`
- Create: `lib/SolutionsIndex.ps1`
- Create: `tests/Run-SolutionsIndexTests.ps1`
- Modify: `knowledge-backup/262r/catalog.json`
- Modify: `knowledge-backup/262r/INDEX.md`
- Modify: `gokuai-workspace-overlay/.agents/skills/legacy-java-converter-vnext/references/pipeline.md`
- Modify: `gokuai-workspace-overlay/.agents/skills/legacy-java-converter-vnext/references/escalation.md`

**Interfaces:**
- Consumes: source profile, target `26.2`, detected API features, primer chain, mapping/dependency evidence.
- Produces: `Find-ConverterSolution([hashtable]$SourceProfile,[string]$Target,[string[]]$Features) -> SolutionMatch[]` and `Write-ConverterSolutionPromotion(...) -> validated index entry plus regression-fixture requirement`.

- [ ] **Step 1: Write failing ordering and applicability tests**

Create fixtures for an exact source/target match, a wrong-target 26.3 entry, and a low-confidence partial feature match. Assert exact 26.2 match sorts first, 26.3 is excluded, and the partial match is advisory rather than auto-applied.

- [ ] **Step 2: Add a promotion-validation test**

Attempt promotion without evidence, validation command/result, deterministic action or AST recipe, and regression fixture. Assert rejection names every missing field. Add a complete entry and assert stable ID generation and catalog insertion are idempotent.

- [ ] **Step 3: Run tests and verify APIs are missing**

Expected: FAIL because `Find-ConverterSolution` is undefined.

- [ ] **Step 4: Implement the focused Solutions Index module**

Normalize existing 262r/solved-case data into matches with `id`, `sourceVersions`, `targetVersion`, `features`, `evidencePaths`, `actionType`, `action`, `validation`, `provenance`, and `confidence`. Exact target is mandatory. Automatic application requires exact applicability plus hardened confidence; all other matches become evidence suggestions.

- [ ] **Step 5: Integrate lookup before AST/fresh reasoning**

Call the module after deterministic lexical transforms and before new AST recipe synthesis. Record queried IDs, applied IDs, rejected reasons, and evidence in the conversion manifest and repair request.

- [ ] **Step 6: Enforce durable promotion**

Promotion requires converter action/recipe, evidence, validation, index update, and a named regression fixture in one change. Update skill pipeline/escalation references to enforce that bundle.

- [ ] **Step 7: Run Solutions Index, manifest, transformation, and AST suites**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-SolutionsIndexTests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-ManifestTests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-TransformationTests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-AstBridgeTests.ps1
```

Expected: all PASS and the wrong-target 26.3 fixture is never selected.

- [ ] **Step 8: Commit executable Solutions Index integration**

```powershell
git add lib/SolutionsIndex.ps1 lib/ConversionCore.ps1 tests/Run-SolutionsIndexTests.ps1 knowledge-backup/262r gokuai-workspace-overlay/.agents/skills/legacy-java-converter-vnext/references
git commit -m "feat: execute known solutions before AI repair"
```

## Task 10: Integrate the two feature branches and verify the live handoff safely

**Files:**
- Modify only after comparison: active files in `C:\GokuCodexAI` corresponding to the reviewed GokuCodexAI feature commit.
- Create during test only: disposable failed-output workspace outside both repositories.

**Interfaces:**
- Consumes: tested LegacyJavaConverter feature branch and tested GokuCodexAI control-plane feature branch.
- Produces: live `C:\GokuCodexAI` native repair path matching committed feature content while preserving unrelated dirty work.

- [ ] **Step 1: Re-run status and compare live dirty files to the feature branch**

For each intended live file, produce a three-way comparison: repository `HEAD`, live dirty version, and feature-branch version. Stop on any overlap whose intent is unclear; do not choose a side by timestamp.

- [ ] **Step 2: Apply only reviewed feature hunks to the live root**

Use `apply_patch` for text changes. Create missing native files explicitly. Do not remove old files or directories. After each file, compare it to the feature branch and document any intentionally retained live-only differences.

- [ ] **Step 3: Validate the live control plane without launching interactive sessions**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\GokuCodexAI\tests\Run-CodexControlPlaneTests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File C:\GokuCodexAI\Validate-GokuAI.ps1
codex mcp list
```

Expected: native tests PASS; `minecraft-knowledge` points only to `C:\GokuCodexAI` paths.

- [ ] **Step 4: Prepare a failed-output fixture through the packaged converter path**

Run `Open-CodexRepairSession.ps1 -PrepareOnly` against a path containing spaces. Verify the full evidence packet, native skill discovery, resolved MCP config, destination-Java tool, and absence of `.grok` creation.

- [ ] **Step 5: Perform one bounded local-worker round trip**

Use a non-production fixture issue that asks the worker to inspect a supplied Java snippet and return structured diagnosis without editing. Verify valid `result.json`, watcher completion, Codex review status, and no unrequested file changes.

- [ ] **Step 6: Verify Codex-only fallback**

Disable the worker in the fixture configuration, run prepare-only/fallback flow, and verify the request remains actionable by Codex with a recoverable worker-unavailable record.

- [ ] **Step 7: Record integration state**

Run `git status --short` in both live repositories. Confirm the original unrelated GokuCodexAI dirty files remain present and no old root was deleted. Do not commit live-only unrelated changes.

## Task 11: Run the complete converter verification ladder and build 3.0.0 artifacts

**Files:**
- Generated, not committed: release/test outputs under the repository's established artifacts directory.
- Modify if failures expose contract gaps: only the owning source/test files from Tasks 2-9, followed by their task-specific test and commit.

**Interfaces:**
- Consumes: integrated feature branches and live native control plane.
- Produces: verified installer and portable artifacts plus a validation report separating build and runtime evidence.

- [ ] **Step 1: Run all converter automated suites**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-RegressionTests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-TransformationTests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-ManifestTests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-CodexHandoffTests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-AstBridgeTests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-SolutionsIndexTests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Run-CodexNativeAuditTests.ps1
```

Expected: every suite PASS. Record exact counts.

- [ ] **Step 2: Build the full solution**

```powershell
dotnet build .\RB.LegacyJavaConverter.sln -c Release
```

Expected: exit 0 with zero errors; investigate warnings introduced by the branch.

- [ ] **Step 3: Build installer and portable release**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Build-Release.ps1
```

Expected: 3.0.0 installer and portable archive. Inspect both inventories for native launcher, sync, overlay, skills, config, and compatibility wrapper; assert no Grok binary/runtime is present.

- [ ] **Step 4: Test one representative successful conversion**

Run a supported fixture through deterministic conversion and destination-Java build. Record source inventory, applied deterministic/Solutions Index/AST stages, preservation reconciliation, jar path, and build status. Do not mark runtime gates passed unless actually exercised.

- [ ] **Step 5: Test one deliberate failed conversion and native repair preparation**

Cause a bounded fixture compile failure, select `Repair with GokuCodexAI`, and verify the generated request/evidence and native session launch. Stop the session before production edits if the fixture purpose is only launch verification.

- [ ] **Step 6: Run runtime/content/behavior validation where available**

Record launch, registry/data, content, assets/models/items/entities, and AI/behavior outcomes independently. Any unexercised gate remains `not_tested`.

- [ ] **Step 7: Hash and record deliverables**

Use `Get-FileHash -Algorithm SHA256` for the installer and portable archive. Record paths, sizes, hashes, suite counts, build warnings/errors, and runtime gate statuses in the execution handoff.

## Task 12: Final review, branch integration decision, and publication gate

**Files:**
- No new product files unless review finds a defect.

**Interfaces:**
- Consumes: both feature branches, complete test evidence, artifact hashes, and live integration comparison.
- Produces: reviewed branches ready for the user-selected merge/push/release action.

- [ ] **Step 1: Use verification-before-completion**

Re-run the shortest commands that directly prove each completion claim. Do not rely on earlier output after subsequent edits.

- [ ] **Step 2: Run whole-branch code review**

Use `superpowers:requesting-code-review` with both specs, this plan, converter branch diff, GokuCodexAI branch diff, test evidence, and the dirty-live-tree preservation notes. Fix accepted findings with their owning test and a focused commit.

- [ ] **Step 3: Re-run affected tests and final audit**

At minimum rerun both control-plane suites, converter regression/handoff/manifest/Solutions Index suites, full solution build, and active Grok dependency audit.

- [ ] **Step 4: Present integration choices**

Use `superpowers:finishing-a-development-branch`. Report converter and GokuCodexAI commits separately, identify any live-only retained differences, and ask before merge, push, release publication, deletion, or duplicate-repository retirement.
