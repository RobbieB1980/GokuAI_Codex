# Session continue — RB Legacy Java Converter 2.10.0

**Read this first** when reopening this worktree. Last saved: **2026-09-02**.

## Status (current)

- Product version for testing: **2.10.0** (GUI + Setup csproj, `version.txt`, tools).
- Includes incremental migration evidence (`MIGRATION_EVIDENCE.md` / `.json`) and MedSystem overlay hardening.
- Station MCreator upstream: `knowledge/_upstream/mcreator` + `MCreator-generator-delta-catalog.md`.
- Knowledge re-index and `Build-Release.ps1` were run for this test build (do not treat as a public GitHub release unless published).
- **CASE-005** gecko_kings_avp_mod: **full restore** jar `…-26.2-full\build\libs\gecko_kings_avp_mod-24.5+mc26.2-neoforge.jar` (~5.9MB) with renderers/models/procedures; primers + CASE remaps encoded. Not in-game verified yet.

## Where things live

| Role | Path |
|---|---|
| Packaging / GitHub repo | `C:\Users\rmbel\Documents\Codex\2026-08-29\referenced-chatgpt-conversation-this-is-an-4\work\LegacyJavaConverter` |
| Dist artifacts | `...\LegacyJavaConverter\dist\` (Setup + Portable) |
| Installed AppData | `C:\Users\rmbel\AppData\Local\RB-Legacy-Java-Converter` |
| Station tools mirror | `C:\rmblocal_llm\projects\RB-Legacy-Java-Converter\tools` |
| Solved knowledge | `C:\rmblocal_llm\knowledge\Solved_Problems\legacy-java-converter-26.2\` |
| MCreator upstream | `C:\rmblocal_llm\knowledge\_upstream\mcreator` |

## Must-read knowledge (agents)

1. `LEARNINGS-2.0.x-handwritten-neoforge.md`
2. `CASE-004-medsystem-1.21.1.md`
3. `OVY-001-overlay-must-be-green-not-oracle.md`
4. `PKG-002-release-version-bump-checklist.md`
5. `MCreator-generator-delta-catalog.md`
6. Playbook: `C:\rmblocal_llm\knowledge\NeoForge_Primers\AGENT-LEGACY-CONVERTER-26.2.md`

## Sensible next work

1. Install/test Setup or portable 2.10.0 — confirm GUI title `v2.10.0` and `MIGRATION_EVIDENCE.*` on a Mode B convert.
2. Publish GitHub release only if testing passes (`Publish-GitHubRelease.ps1 -Tag v2.10.0`).
3. Do not rebuild MedSystem overlay from broken oracle sources.
4. CASE-005 next wave: **in-game verify** AVP entities on NeoForge 26.2.0.72 (render + procedure AI). Optionally promote `…-26.2-full` over the older gated tree.

## Do not redo

- Do not claim public release success without Setup + Portable artifacts and a green test convert.
- Do not embed full MCreator git tree in the installer.
