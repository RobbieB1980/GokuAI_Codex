# Session continue — RB Legacy Java Converter 2.10.5

**Read this first** when reopening this worktree. Last saved: **2026-09-03**.

## Status (current)

- Product version: **2.10.5** (GUI Setup + Portable rebuilt; MobEffect remaps in real `262-repair`).
- Dist:
  - `...\LegacyJavaConverter\dist\RB-Legacy-Java-Converter-Setup.exe` (~134.9 MB)
  - `...\LegacyJavaConverter\dist\RB-Legacy-Java-Converter-Portable.zip` (~66.4 MB)
- Desktop copies: `RB-Legacy-Java-Converter-Setup.exe` + `RB-Legacy-Java-Converter-Portable.zip`
- AppData synced (`version.txt` = 2.10.5; tools hotfix present).
- Test1 repaired: `gradlew build` → `gecko_kings_avp_mod-24.5+mc26.2-neoforge.jar` (~5.9MB; 80/43/93).
- **Published** GitHub `v2.10.5` on `RobbieB1980/LegacyJavaConverter` (commit `de8ee14`).
  - https://github.com/RobbieB1980/LegacyJavaConverter/releases/tag/v2.10.5

## Why 2.10.5 (installer green/fail loop)

Hand repairs patched the **output folder**. Notes claimed CASE-005 potion remaps were in `262-repair`, but they lived only in `Invoke-McreatorForge1201ResiduePass` (gated on profile pass `mcreator-1.20.1`). NeoForge **1.21.x** jobs enable `mcreator-1.21.x` only, so Mode B never applied `applyEffectTick(ServerLevel,…)` / `renderInventoryText` strip.

**Fix:** remaps now in `Invoke-Minecraft262CompileRepairPass` (every route + post-MCreator sweep). Residue keeps an idempotent copy.

## Where things live

| Role | Path |
|---|---|
| Packaging / GitHub repo | `C:\Users\rmbel\Documents\Codex\2026-08-29\referenced-chatgpt-conversation-this-is-an-4\work\LegacyJavaConverter` |
| Dist artifacts | `...\LegacyJavaConverter\dist\` |
| Installed AppData | `C:\Users\rmbel\AppData\Local\RB-Legacy-Java-Converter` |
| Station tools mirror | `C:\rmblocal_llm\projects\RB-Legacy-Java-Converter\tools` |
| Solved knowledge | `C:\rmblocal_llm\knowledge\Solved_Problems\legacy-java-converter-26.2\` |

## Sensible next work

1. Install Desktop Setup **or** unzip Portable; confirm GUI title **v2.10.5**.
2. Mode B re-run gecko_kings 1.21.1 with **Compile after convert**; expect installable jar without hand repair.
3. When Xbox is up: in-game verify CASE-005 jar on NeoForge 26.2.0.72.

## Do not redo

- Do not put 26.2-universal remaps only on a version-gated residue pass.
- Do not invent a permanent client renderer compile-gate when entity-render-state submit path applies.
- Do not claim public GitHub release without publishing Setup + Portable.
