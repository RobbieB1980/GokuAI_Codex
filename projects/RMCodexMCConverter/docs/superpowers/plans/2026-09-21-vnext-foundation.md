# LegacyJavaConverter vNext Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish a reproducible NeoForge 26.2 baseline, preserve all installed hardened fixes, and add tested conversion-manifest and Java AST-worker boundaries without replacing proven semantic conversion passes.

**Architecture:** PowerShell remains the compatibility orchestrator while hardened transformations move into focused, directly testable modules. A JavaParser-based JVM worker accepts versioned JSON requests and returns structured results; the first slice runs it only against fixtures and shadow comparisons. Release metadata and portable contents become manifest-driven so the upstream source, installed workspace, and packaged converter cannot silently diverge.

**Tech Stack:** PowerShell 5.1+, .NET 8 WinForms, Java 25, Gradle, JavaParser Symbol Solver, Pester-free PowerShell regression harness, JSON/JSONL contracts.

**Spec:** `docs/superpowers/specs/2026-09-21-vnext-architecture-design.md`

## Global Constraints

- Target Minecraft/NeoForge remains 26.2; default NeoForge is `26.2.0.72`.
- Destination builds use JDK 25.
- Detected source versions earlier than 1.20.1 remain out of scope.
- Inputs are never modified.
- Existing proven deterministic fixes remain active until an equivalent tested vNext implementation replaces them.
- Exact 26.2 physical source is authoritative for target API claims.
- A successful `gradlew build` is reported separately from runtime correctness.
- GokuCodexAI is not invoked by this implementation slice.

## Review Focus

- Four-part NeoForge versions and ranges must retain every numeric component; Task 1 adds direct normalization and routing tests.
- Re-running hardened transformations must produce byte-identical output; Tasks 2 and 4 add idempotence fixtures.
- Java-looking text in comments and string literals must not be rewritten by AST recipes; Task 7 adds negative contract fixtures.
- Resource transformations must preserve unrelated JSON keys and arrays; Task 2 adds structural before/after assertions.
- Packaging must fail when a required portable file is missing or differs from the manifest; Task 3 adds manifest verification tests.

---

### Task 1: Repair the red version-normalization baseline

**Files:**
- Modify: `lib/ConversionCore.ps1:1-8`
- Modify: `tests/Run-RegressionTests.ps1:28-50`

**Interfaces:**
- Consumes: arbitrary metadata text passed to `ConvertTo-NormalizedMinecraftVersion`.
- Produces: the first supported Minecraft/NeoForge version token as a string, retaining two through four numeric components where valid.

- [ ] **Step 1: Expand the failing version tests**

Add these assertions before changing production code:

```powershell
Assert-Equal (ConvertTo-NormalizedMinecraftVersion 'neoforge-26.2.0.72') '26.2.0.72' 'four-part NeoForge version normalization'
Assert-Equal (ConvertTo-NormalizedMinecraftVersion '[26.1.0.9,26.2)') '26.1.0.9' 'four-part NeoForge range normalization'
Assert-Equal (ConvertTo-NormalizedMinecraftVersion '26.2') '26.2' 'two-part target normalization'
Assert-Equal (ConvertTo-NormalizedMinecraftVersion 'minecraft 1.21.11') '1.21.11' 'three-part Minecraft normalization'
Assert-Equal (ConvertTo-NormalizedMinecraftVersion '126.2.0.72') '' 'embedded numeric token rejected'
```

- [ ] **Step 2: Run the focused suite and verify the intended failure**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests\Run-RegressionTests.ps1
```

Expected: FAIL on `four-part NeoForge version normalization`, returning `26.2.0`.

- [ ] **Step 3: Correct the version matcher**

Replace the matcher with a bounded expression that supports the existing Minecraft forms and up to four-part post-1.21 versions:

```powershell
$hits = [regex]::Matches($Value, '(?<![\d.])(?:1\.(?:20|21)\.\d+|2[2-6](?:\.\d+){1,3})(?![\d.])')
```

- [ ] **Step 4: Run regression tests**

Run the command from Step 2.

Expected: the normalization assertions pass and the suite proceeds through all existing checks.

- [ ] **Step 5: Commit**

```powershell
git add lib/ConversionCore.ps1 tests/Run-RegressionTests.ps1
git commit -m "fix: preserve full NeoForge versions"
```

### Task 2: Reconcile installed-only hardened 26.2 transformations

**Files:**
- Create: `lib/Minecraft262HardenedTransforms.ps1`
- Modify: `Convert-Forge1201-ToNeoForge262.ps1:42,2207,3992-4050,4352-4356`
- Create: `tests/fixtures/hardened-262/leaf-api/input.java`
- Create: `tests/fixtures/hardened-262/leaf-api/expected.java`
- Create: `tests/fixtures/hardened-262/tree-feature/input.json`
- Create: `tests/fixtures/hardened-262/tree-feature/expected.json`
- Create: `tests/fixtures/hardened-262/client-item/input.json`
- Create: `tests/fixtures/hardened-262/client-item/expected.json`
- Modify: `tests/Run-RegressionTests.ps1`

**Interfaces:**
- Produces: `Convert-Minecraft262LeafApiText([string]$Text) -> string`.
- Produces: `Convert-Minecraft262TreeConfiguredFeatureDocument([string]$JsonText) -> string`.
- Produces: `Convert-Minecraft262ClientItemDocument([string]$JsonText, [string]$ModId) -> string`.
- Consumed by: the existing compile-repair, tree-resource, and client-item passes.

- [ ] **Step 1: Add direct fixture assertions that fail because the functions do not exist**

Dot-source the new module from the regression script and compare each input to its expected output:

```powershell
. (Join-Path $repo 'lib\Minecraft262HardenedTransforms.ps1')

$leafInput = Get-Content (Join-Path $repo 'tests\fixtures\hardened-262\leaf-api\input.java') -Raw
$leafExpected = Get-Content (Join-Path $repo 'tests\fixtures\hardened-262\leaf-api\expected.java') -Raw
$leafActual = Convert-Minecraft262LeafApiText -Text $leafInput
Assert-Equal $leafActual $leafExpected 'installed leaf API wave'
Assert-Equal (Convert-Minecraft262LeafApiText -Text $leafActual) $leafActual 'leaf API wave idempotence'
```

Add equivalent first-run and idempotence assertions for tree-feature and client-item JSON.

- [ ] **Step 2: Verify the new fixture tests fail**

Run the regression suite.

Expected: FAIL because `Minecraft262HardenedTransforms.ps1` or its functions are absent.

- [ ] **Step 3: Implement the leaf API text transform**

Move the installed workspace's additional MCreator 1.21.4 replacements into `Convert-Minecraft262LeafApiText`. Include the proven clock, lightning, key mapping, cow/pig model package, MobRenderer generic, registerBlock supplier, GUI tooltip/render-state, PickaxeItem, RenderTypes import, and SavedData repairs. Apply a stable ordered sequence and return unchanged text when no rule matches.

- [ ] **Step 4: Implement structural tree configured-feature conversion**

Parse JSON with `ConvertFrom-Json`, require `type == 'minecraft:tree'`, and only migrate documents with `config.dirt_provider` and no `config.below_trunk_provider`. Move the state provider into a `minecraft:rule_based_state_provider`, remove `dirt_provider` and `force_dirt`, serialize at depth 100, and preserve all unrelated properties.

- [ ] **Step 5: Implement the client-item model conversion**

Parse JSON and change only an exact `model.model == 'minecraft:item/template_spawn_egg'` reference to `<modid>:item/template_spawn_egg`. Leave different models, comments represented as keys, and unrelated strings unchanged.

- [ ] **Step 6: Wire the module into the converter**

Dot-source the module next to `ConversionCore.ps1`. Invoke `Convert-Minecraft262LeafApiText` once from `Invoke-Minecraft262CompileRepairPass`. Replace the installed-only tree function with a thin file traversal that calls `Convert-Minecraft262TreeConfiguredFeatureDocument`, and use `Convert-Minecraft262ClientItemDocument` inside the item-model pass.

- [ ] **Step 7: Run regression tests twice**

Run the suite twice in separate processes.

Expected: both runs pass with identical fixture output and no repository changes.

- [ ] **Step 8: Commit**

```powershell
git add lib/Minecraft262HardenedTransforms.ps1 Convert-Forge1201-ToNeoForge262.ps1 tests
git commit -m "fix: reconcile hardened NeoForge 26.2 transforms"
```

### Task 3: Make releases and portable contents reproducible

**Files:**
- Create: `eng/Version.props`
- Create: `eng/portable-manifest.json`
- Create: `scripts/Test-PortableManifest.ps1`
- Modify: `scripts/Build-Release.ps1:60-135`
- Modify: `src/RB.LegacyJavaConverter/RB.LegacyJavaConverter.csproj:14-36`
- Modify: `src/RB.LegacyJavaConverter.Setup/RB.LegacyJavaConverter.Setup.csproj:14-16`
- Modify: `tests/Run-RegressionTests.ps1`
- Modify: `README.md:1-5`

**Interfaces:**
- `eng/Version.props` produces MSBuild properties `Version`, `FileVersion`, and `InformationalVersion` for both applications.
- `eng/portable-manifest.json` produces the authoritative required path list for the portable package.
- `scripts/Test-PortableManifest.ps1 -Root <path> -ManifestPath <path>` exits nonzero and lists missing files when contents are incomplete.

- [ ] **Step 1: Add failing release metadata tests**

Assert that both project files import `eng/Version.props`, neither contains a literal `<Version>`, and the portable manifest contains the converter scripts, all `lib` indexes, overlays, client-item assets, migration ledgers, docs, and helper scripts.

- [ ] **Step 2: Add a failing portable-manifest validator test**

Create a temporary directory containing only one declared file, run `Test-PortableManifest.ps1`, and assert a nonzero exit plus the missing path in captured output.

- [ ] **Step 3: Verify the release tests fail**

Run the regression suite.

Expected: FAIL because the version props, manifest, and validator do not exist.

- [ ] **Step 4: Add the single version source**

Create `eng/Version.props`:

```xml
<Project>
  <PropertyGroup>
    <Version>2.11.0</Version>
    <FileVersion>2.11.0.0</FileVersion>
    <InformationalVersion>2.11.0-vnext.1</InformationalVersion>
  </PropertyGroup>
</Project>
```

Import it from both application projects and remove duplicate version literals.

- [ ] **Step 5: Add and enforce the portable manifest**

Represent required paths as repository-relative strings. Make the validator check exact files and recursive directory entries. Update `Build-Release.ps1` to validate the repository source set before publishing and the portable tree after copying.

- [ ] **Step 6: Generate `version.txt` without editing tracked source during release**

Read `Version` from `eng/Version.props` and write only the copy under the temporary portable output. Remove the existing fallback that writes a missing root `version.txt` during a build. Assert that the tracked root file equals the declared version until its eventual removal in a later release migration.

- [ ] **Step 7: Update the README version from the shared source**

Set the documented vNext baseline to `2.11.0-vnext.1` and NeoForge 26.2. Do not change runtime support claims.

- [ ] **Step 8: Verify and commit**

Run regression tests and `scripts\Test-PortableManifest.ps1` against the repository layout.

```powershell
git add eng scripts/Build-Release.ps1 scripts/Test-PortableManifest.ps1 src README.md tests/Run-RegressionTests.ps1
git commit -m "build: make vNext release contents reproducible"
```

### Task 4: Add transformation golden fixtures and isolated test loading

**Files:**
- Create: `tests/TestHelpers.ps1`
- Create: `tests/Run-TransformationTests.ps1`
- Create: `tests/fixtures/mechanical/resource-location/input.java`
- Create: `tests/fixtures/mechanical/resource-location/expected.java`
- Create: `tests/fixtures/mechanical/comment-and-string/input.java`
- Create: `tests/fixtures/mechanical/comment-and-string/expected.java`
- Modify: `Convert-Forge1201-ToNeoForge262.ps1`
- Modify: `tests/Run-RegressionTests.ps1`

**Interfaces:**
- Produces: `Assert-TextFixture -Transform <scriptblock> -FixtureRoot <path> -Name <string>`.
- Produces: `LEGACY_CONVERTER_LOAD_ONLY=1`, which loads converter functions without executing the main conversion pipeline.

- [ ] **Step 1: Add a failing load-only test**

Set `$env:LEGACY_CONVERTER_LOAD_ONLY = '1'`, dot-source the converter, and assert that `Invoke-MechanicalJavaRewrites` exists and no output directory was created.

- [ ] **Step 2: Verify the test fails because dot-sourcing executes the main pipeline**

Run `tests\Run-TransformationTests.ps1`.

Expected: FAIL before fixture execution because mandatory conversion arguments or main-pipeline side effects are encountered.

- [ ] **Step 3: Add a main-entry guard**

Wrap only the bottom-level pipeline in:

```powershell
if ($env:LEGACY_CONVERTER_LOAD_ONLY -ne '1') {
    Invoke-LegacyConversionMain
}
```

Move the current bottom-level statements into `Invoke-LegacyConversionMain` without changing their order or behavior.

- [ ] **Step 4: Add the fixture helper and mechanical fixtures**

`Assert-TextFixture` reads `input.java` and `expected.java`, runs a transform in a temporary project tree, compares exact text, then runs the transform again and compares the second result byte-for-byte.

The comment-and-string fixture contains `ResourceLocation` in a comment, a string literal, a project-defined class, and an actual Minecraft import. Record the current legacy behavior in `expected.java`; do not improve it in this task.

- [ ] **Step 5: Run both suites and commit**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests\Run-RegressionTests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests\Run-TransformationTests.ps1
git add Convert-Forge1201-ToNeoForge262.ps1 tests
git commit -m "test: add golden transformation harness"
```

### Task 5: Establish the conversion-manifest contract

**Files:**
- Create: `lib/ConversionManifest.ps1`
- Create: `docs/schemas/conversion-manifest.schema.json`
- Create: `tests/Run-ManifestTests.ps1`

**Interfaces:**
- Produces: `New-ConversionManifest([string]$InputPath, [string]$TargetMinecraft, [string]$TargetNeoForge, [string]$ConverterVersion) -> ordered hashtable`.
- Produces: `Add-ManifestRule([hashtable]$Manifest, [string]$RuleId, [string[]]$Files, [string]$Evidence) -> void`.
- Produces: `Set-ManifestValidation([hashtable]$Manifest, [ValidateSet('intake','deterministic','javaParsed','built','clientBooted','worldLoaded','contentSmokeTested')] [string]$Stage, [ValidateSet('notRun','passed','failed','blocked')] [string]$Status, [string]$EvidencePath) -> void`.
- Produces: `Write-ConversionManifest([hashtable]$Manifest, [string]$Path) -> void`.

- [ ] **Step 1: Write schema and failing contract tests**

Tests create a temporary input file, call `New-ConversionManifest`, and assert schema version `1`, SHA-256 input hash, exact 26.2 target values, empty rule list, and all validation stages initialized to `notRun`.

- [ ] **Step 2: Verify tests fail because the module is absent**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests\Run-ManifestTests.ps1
```

- [ ] **Step 3: Implement deterministic manifest creation**

Use ordered hashtables, UTC ISO-8601 timestamps only for run metadata, forward-slash relative paths, SHA-256 hashes, and `ConvertTo-Json -Depth 100`. Sort file and rule arrays before serialization so repeated runs over identical input differ only in the documented run timestamp.

- [ ] **Step 4: Implement rule and validation updates**

Reject duplicate rule IDs with conflicting evidence. Allow repeated identical additions as no-ops. Reject advancing a later validation stage to `passed` when its immediately preceding stage is not `passed`.

- [ ] **Step 5: Run manifest tests twice and commit**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests\Run-ManifestTests.ps1
git add lib/ConversionManifest.ps1 docs/schemas/conversion-manifest.schema.json tests/Run-ManifestTests.ps1
git commit -m "feat: define vNext conversion manifest contract"
```

### Task 6: Create the JavaParser AST worker protocol

**Files:**
- Create: `tools/ast-worker/settings.gradle`
- Create: `tools/ast-worker/build.gradle`
- Create: `tools/ast-worker/src/main/java/rb/legacy/ast/Main.java`
- Create: `tools/ast-worker/src/main/java/rb/legacy/ast/Protocol.java`
- Create: `tools/ast-worker/src/main/java/rb/legacy/ast/AnalysisService.java`
- Create: `tools/ast-worker/src/test/java/rb/legacy/ast/ProtocolTest.java`
- Create: `tools/ast-worker/src/test/java/rb/legacy/ast/AnalysisServiceTest.java`
- Create: `tools/Build-AstWorker.ps1`
- Modify: `eng/portable-manifest.json`

**Interfaces:**
- Consumes one UTF-8 JSON request on stdin: `{"protocolVersion":1,"operation":"analyze","sourceRoot":"<absolute path>","classpath":[]}`.
- Produces one UTF-8 JSON response on stdout containing `protocolVersion`, `status`, `parsedFiles`, `parseFailures`, `declaredTypes`, `imports`, and `diagnostics`.
- Exit code `0` means a valid response, `2` means invalid request, and `3` means worker failure.

- [ ] **Step 1: Create failing protocol tests**

Test valid request deserialization, rejection of protocol version `2`, rejection of an operation other than `analyze`, and stable JSON response field names.

- [ ] **Step 2: Create a failing analysis test**

Use a temporary source root containing one valid Java class and one malformed file. Expect one parsed file, one parse failure with its relative path, the valid declared type, and its import list.

- [ ] **Step 3: Verify Gradle tests fail**

Run:

```powershell
gradle -p tools\ast-worker test --no-daemon
```

Expected: FAIL because the worker classes do not exist.

- [ ] **Step 4: Implement the worker with JavaParser Symbol Solver**

Use JavaParser `3.28.2` and `javaparser-symbol-solver-core`. Configure `CombinedTypeSolver` with reflection, the source root, and any supplied classpath JARs. Analysis must continue after individual parse failures and must not modify sources.

- [ ] **Step 5: Add the worker build script**

`tools/Build-AstWorker.ps1` resolves destination Java through `Resolve-Java`, runs Gradle tests, builds a self-contained distribution, and copies it to `tools/lib/ast-worker/`. Add that output path to the portable manifest.

- [ ] **Step 6: Run worker tests and commit**

```powershell
gradle -p tools\ast-worker clean test installDist --no-daemon
git add tools/ast-worker tools/Build-AstWorker.ps1 eng/portable-manifest.json
git commit -m "feat: add JavaParser analysis worker"
```

### Task 7: Add the PowerShell AST bridge and shadow comparison

**Files:**
- Create: `lib/AstWorkerBridge.ps1`
- Create: `tests/Run-AstBridgeTests.ps1`
- Create: `tests/fixtures/ast-analysis/valid/Example.java`
- Create: `tests/fixtures/ast-analysis/mixed/Good.java`
- Create: `tests/fixtures/ast-analysis/mixed/Broken.java`
- Modify: `eng/portable-manifest.json`

**Interfaces:**
- Produces: `Invoke-LegacyAstWorker([string]$SourceRoot, [string[]]$Classpath, [string]$WorkerRoot) -> PSCustomObject`.
- Produces: `Compare-LegacyAndAstInventory([string]$SourceRoot, [pscustomobject]$AstResult) -> PSCustomObject` with `MissingFromAst`, `OnlyInAst`, and `ParseFailures`.

- [ ] **Step 1: Write failing bridge tests**

Assert correct paths containing spaces, UTF-8 source handling, valid response parsing, protocol mismatch rejection, nonzero worker exit handling, and preservation of parse-failure diagnostics.

- [ ] **Step 2: Verify bridge tests fail**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests\Run-AstBridgeTests.ps1
```

- [ ] **Step 3: Implement process invocation without shell interpolation**

Use `System.Diagnostics.ProcessStartInfo`, redirect stdin/stdout/stderr, serialize the request with `ConvertTo-Json -Compress`, and pass paths only inside JSON. Never construct a command line containing source paths.

- [ ] **Step 4: Implement shadow inventory comparison**

Compare AST-declared types/imports with the existing source-profile feature inventory. Report differences without changing conversion routing or files.

- [ ] **Step 5: Verify and commit**

Run the worker tests and bridge tests, then:

```powershell
git add lib/AstWorkerBridge.ps1 tests eng/portable-manifest.json
git commit -m "feat: add AST worker bridge in shadow mode"
```

### Task 8: Verify the complete foundation slice

**Files:**
- Modify: `README.md`
- Modify: `docs/ARCHITECTURE.md`
- Create: `docs/VNEXT-STATUS.md`

**Interfaces:**
- Produces: a documented, reproducible handoff describing current completion stages, legacy/AST boundaries, and commands needed to validate the branch.

- [ ] **Step 1: Document the implemented boundary**

State that AST analysis is present but production rewrites still use the proven deterministic passes. List the exact validation stages and explicitly distinguish build from runtime verification.

- [ ] **Step 2: Run every focused suite**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests\Run-RegressionTests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests\Run-TransformationTests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests\Run-ManifestTests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests\Run-AstBridgeTests.ps1
gradle -p tools\ast-worker clean test installDist --no-daemon
```

Expected: all suites pass.

- [ ] **Step 3: Build the Windows applications**

```powershell
dotnet build RB.LegacyJavaConverter.slnx -c Release
```

Expected: build succeeds with no errors.

- [ ] **Step 4: Build and validate the portable package**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\Build-Release.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\Test-PortableManifest.ps1 -Root dist\portable\RB-Legacy-Java-Converter -ManifestPath eng\portable-manifest.json
```

Expected: release build succeeds and every required file is present.

- [ ] **Step 5: Confirm repository cleanliness constraints**

Run `git status --short` and verify only intended documentation changes remain before the final documentation commit. Confirm no generated `bin`, `obj`, worker build, or `dist` files are staged.

- [ ] **Step 6: Commit documentation**

```powershell
git add README.md docs/ARCHITECTURE.md docs/VNEXT-STATUS.md
git commit -m "docs: record vNext foundation status"
```

- [ ] **Step 7: Request whole-branch review**

Review every commit against `docs/superpowers/specs/2026-09-21-vnext-architecture-design.md`, with special attention to input preservation, target 26.2 pinning, PowerShell 5.1 compatibility, fixture idempotence, packaging completeness, and the fact that AST operation remains shadow-only.
