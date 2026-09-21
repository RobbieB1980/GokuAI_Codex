# Session continue — RB Legacy Java Converter 2.0.3

**Read this first** when reopening this worktree. Last saved: **2026-09-02**.

## Status (current)

- Product baseline is **2.0.3** (README + version markers). Premature 2.0.4 labels were rolled back.
- MedSystem NeoForge **1.21.1 → 26.2** Mode B path is green (`CASE-004`); overlay hardening lives under **Unreleased** until a real bump.
- **Incremental migration evidence** is wired:
  - Convert emits `MIGRATION_EVIDENCE.md` / `.json` (NeoForge `primer_changes` + GeckoLib/MCreator when signaled).
  - Bundled stubs: `tools/lib/primer_changes/`, `tools/lib/dep_changes/`.
  - Station MCreator upstream: `knowledge/_upstream/mcreator` + `MCreator-generator-delta-catalog.md`.
- ExactPrimer / GeckoLib / MCreator passes are still the executors; evidence is query-filtered incremental provenance.

## Where things live

| Role | Path |
|---|---|
| Packaging / GitHub repo | `C:\Users\rmbel\Documents\Codex\2026-08-29\referenced-chatgpt-conversation-this-is-an-4\work\LegacyJavaConverter` |
| Installed AppData | `C:\Users\rmbel\AppData\Local\RB-Legacy-Java-Converter` (`version.txt` = 2.0.3) |
| Station tools mirror | `C:\rmblocal_llm\projects\RB-Legacy-Java-Converter\tools` |
| Solved knowledge | `C:\rmblocal_llm\knowledge\Solved_Problems\legacy-java-converter-26.2\` |
| MCreator upstream | `C:\rmblocal_llm\knowledge\_upstream\mcreator` |
| MCreator generator catalog | `...\legacy-java-converter-26.2\MCreator-generator-delta-catalog.md` |
| Fresh MedSystem 26.2 project | `C:\Users\rmbel\Downloads\medsystem-neoforge-2.12.1+1.21.1-26.2` |
| Green reference (user renamed old) | `C:\Users\rmbel\Downloads\oldmedsystem-neoforge-2.12.1+1.21.1-26.2` |

## Must-read knowledge (agents)

1. `LEARNINGS-2.0.x-handwritten-neoforge.md`
2. `CASE-004-medsystem-1.21.1.md`
3. `DFU-001-recordcodecbuilder-validate-mixin.md`
4. `OVY-001-overlay-must-be-green-not-oracle.md`
5. `INT-001-soft-dep-integration-exclude.md`
6. `PKG-002-release-version-bump-checklist.md`
7. `MCreator-generator-delta-catalog.md`
8. Playbook: `C:\rmblocal_llm\knowledge\NeoForge_Primers\AGENT-LEGACY-CONVERTER-26.2.md`

## Key technical facts

- Overlays apply **after** DFU → overlay must already be green.
- Soft-dep exclude matches path `integration/carryon|sable|…` not only hard imports.
- Evidence packet prefers station `primer_changes` shards; offline installs use bundled index stubs.
- MCreator master currently has `generator-1.21.1` + `generator-26.1.x` only (no `generator-26.2` yet).
- Release bump requires GUI+Setup **csproj** versions + `Build-Release.ps1` (not tools-only).

## Sensible next work

1. Re-index knowledge so MCP sees `_upstream/mcreator` (`Update-Knowledge.ps1`).
2. Fresh Mode B reconvert to confirm `MIGRATION_EVIDENCE.*` appears on a real mod.
3. Ship a real **2.0.4** only after evidence + overlay Unreleased items are accepted (PKG-002).
4. Encode another mod / deepen MCreator generator diffs when needed.

## Do not redo

- Do not rebuild MedSystem overlay from `old_medsystem_26.2_oracle_src` (broken DFU).
- Do not claim success without `build/libs` jar when packaging is requested.
- Do not leave GUI version hard-coded when bumping releases.
- Do not embed the full MCreator git tree in Setup.exe / portable zip.
