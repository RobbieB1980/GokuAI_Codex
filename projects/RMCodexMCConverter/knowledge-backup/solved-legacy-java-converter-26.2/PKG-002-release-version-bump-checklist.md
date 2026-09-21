# PKG-002 — Release version bump checklist (GUI must match tools)

## Symptom

Tools under `%LOCALAPPDATA%\RB-Legacy-Java-Converter\tools` already contain new converter logic (e.g. 2.0.3 MedSystem fixes), but the **GUI window title still says v1.5.5**.

## Root cause

Product version lives in **multiple places**. Updating only `tools/` or `version.txt` does not rebuild the WinForms EXE. Hard-coded title strings in `MainForm.cs` / `SetupForm.cs` can also lag behind `.csproj` `<Version>`.

## Checklist (every public release)

Authoring / packaging repo: `LegacyJavaConverter` (GitHub `RobbieB1980/LegacyJavaConverter`).

1. **Bump** in both:
   - `src/RB.LegacyJavaConverter/RB.LegacyJavaConverter.csproj` → `Version` / `FileVersion` / `InformationalVersion`
   - `src/RB.LegacyJavaConverter.Setup/RB.LegacyJavaConverter.Setup.csproj` → same
2. **UI titles** must read assembly version (preferred) or the same literal — never leave `v1.5.5` hard-coded.
3. Write root **`version.txt`** (e.g. `2.0.4`). `Build-Release.ps1` copies it into the portable root.
4. Sync **tools truth** into the packaging repo root (`Convert-*.ps1`, `lib/`, `CHANGELOG.md`, overlays).
5. Run `scripts/Build-Release.ps1` → `dist/RB-Legacy-Java-Converter-Setup.exe` + Portable zip.
6. Install/verify: EXE `FileVersion`, GUI title, `version.txt`, and a known Mode B reconvert.
7. Publish: `scripts/Publish-GitHubRelease.ps1 -Tag vX.Y.Z` (uploads Setup + Portable).

## Related

- `PKG-001-installer-embedded-payload-only.md`
- GitHub releases: https://github.com/RobbieB1980/LegacyJavaConverter/releases
