# Session continue — RB Legacy Java Converter 2.10.3

**Read this first** when reopening this worktree. Last saved: **2026-09-02**.

## Status (current)

- Product version: **2.10.3** (GUI Setup + Portable rebuilt with CASE-005 Mode B remaps that 2.10.2 still missed).
- Dist:
  - `C:\Users\rmbel\Documents\Codex\2026-08-29\referenced-chatgpt-conversation-this-is-an-4\work\LegacyJavaConverter\dist\RB-Legacy-Java-Converter-Setup.exe` (~134.9 MB)
  - `C:\Users\rmbel\Documents\Codex\2026-08-29\referenced-chatgpt-conversation-this-is-an-4\work\LegacyJavaConverter\dist\RB-Legacy-Java-Converter-Portable.zip` (~66.4 MB)
- AppData synced from portable tools + EXE (`%LOCALAPPDATA%\RB-Legacy-Java-Converter`).
- Test1 failed output repaired again same day: `gradlew build` → `gecko_kings_avp_mod-24.5+mc26.2-neoforge.jar` (~5.9MB; 80/43/93).
- **Published** GitHub `v2.10.3` on `RobbieB1980/LegacyJavaConverter` (commit `ecf1fde`); Setup + Portable rebuilt and copied to Desktop.

## 2.10.3 remaps (why rebuild)

- `block-item-id`: `REGISTRY.register("id", FooBlock::new)` → `registerBlock` when ctor takes `Properties`
- `262-repair`: acid/projectile `submit` / `extractRenderState` (ArrowRenderer / entity-render-state)
- `262-repair`: stronger nested `Registries.ARMOR_MATERIAL` → static `ArmorMaterial`
- `262-repair` hotfix: `registerItemExtensions` stub — balanced braces + real newlines (not single-quoted literal `` `r`n ``)
- `262-repair` hotfix: `EntityType.Builder.<AcidEntity>of` for AbstractArrow factories; hardened `applyEffectTick(ServerLevel,…)` + `renderInventoryText` strip
- Build host Java: converter `-Compile` uses `Invoke-GradleBuildWithRequiredJava` → **JDK 25** + wrapper **Gradle 9.2.1**

## Where things live

| Role | Path |
|---|---|
| Packaging / GitHub repo | `C:\Users\rmbel\Documents\Codex\2026-08-29\referenced-chatgpt-conversation-this-is-an-4\work\LegacyJavaConverter` |
| Dist artifacts | `...\LegacyJavaConverter\dist\` |
| Installed AppData | `C:\Users\rmbel\AppData\Local\RB-Legacy-Java-Converter` |
| Station tools mirror | `C:\rmblocal_llm\projects\RB-Legacy-Java-Converter\tools` |
| Solved knowledge | `C:\rmblocal_llm\knowledge\Solved_Problems\legacy-java-converter-26.2\` |

## Sensible next work

1. Install Setup **or** unzip Portable; confirm GUI title **v2.10.3**.
2. Mode B re-run gecko_kings 1.21.1 jar with **Compile after convert**; expect installable jar without client gate.
3. When Xbox is up: in-game verify CASE-005 jar on NeoForge 26.2.0.72.
4. Publish GitHub release only if desired (`Publish-GitHubRelease.ps1 -Tag v2.10.3`).

## Do not redo

- Do not claim public GitHub release without publishing Setup + Portable.
- Do not invent a permanent client renderer compile-gate when entity-render-state submit path applies.
- Do not rebuild MedSystem overlay from broken oracle sources.
