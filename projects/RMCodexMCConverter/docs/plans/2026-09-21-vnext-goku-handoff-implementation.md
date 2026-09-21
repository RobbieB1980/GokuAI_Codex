# vNext GokuCodexAI failure handoff implementation plan

## 1. Specify failing handoff tests

- Add a temporary-workspace test harness for repository and portable layouts.
- Assert stale-skill replacement, paths with spaces, required tools, and
  fail-closed behaviour.
- Assert that the generated prompt invokes vNext orchestration before focused
  failed-output repair.

## 2. Create the shared vNext skill

- Scaffold `legacy-java-converter-vnext` in the repository overlay.
- Add concise workflow instructions and focused references for architecture,
  validation, preservation, and escalation.
- Register it in `Agents.md`, the failed-output skill, and skill linting.

## 3. Harden synchronization

- Make `Sync-GokuaiConverterWorkspace.ps1` detect repository and portable
  layouts without machine-specific fallbacks.
- Copy the complete overlay and current converter tools, libraries, and AST
  runtime.
- Add explicit post-sync verification.

## 4. Wire the failure launcher

- Synchronize and verify before knowledge setup and prompt generation.
- Add a no-launch test seam without weakening production defaults.
- Update the generated prompt with the vNext skill order.

## 5. Package the handoff bundle

- Add the overlay and synchronization script to the portable manifest,
  application output, and release assembly.
- Extend manifest/regression checks for the new required content.

## 6. Verify

- Run skill validation and handoff tests.
- Run regression, transformation, manifest, and AST bridge tests.
- Build the Java AST worker and .NET solution.
- Build and validate a portable release without modifying the live Goku
  workspace.
