# Session continue — RB Legacy Java Converter 2.10.4

**Read this first** when reopening this worktree. Last saved: **2026-09-03**.

## Status (current)

- Product version: **2.10.4** (GUI Setup + Portable rebuilt with CASE-005 Mode B leftover remaps).
- Dist:
  - `C:\Users\rmbel\Documents\Codex\2026-08-29\referenced-chatgpt-conversation-this-is-an-4\work\LegacyJavaConverter\dist\RB-Legacy-Java-Converter-Setup.exe` (~134.9 MB)
  - `C:\Users\rmbel\Documents\Codex\2026-08-29\referenced-chatgpt-conversation-this-is-an-4\work\LegacyJavaConverter\dist\RB-Legacy-Java-Converter-Portable.zip` (~66.4 MB)
- Desktop copies: `RB-Legacy-Java-Converter-Setup.exe` + `RB-Legacy-Java-Converter-Portable.zip`
- AppData synced from portable tools + EXE (`%LOCALAPPDATA%\RB-Legacy-Java-Converter`).
- Test1 failed output repaired: `gradlew build` → `gecko_kings_avp_mod-24.5+mc26.2-neoforge.jar` (~5.9MB; 80/43/93).
- **Published** GitHub `v2.10.4` on `RobbieB1980/LegacyJavaConverter` (commit `3910ae0`); Setup + Portable rebuilt and copied to Desktop.
  - https://github.com/RobbieB1980/LegacyJavaConverter/releases/tag/v2.10.4

## 2.10.4 remaps (why rebuild)

- `262-repair`: `registerItemExtensions` stub **ungated** from `Registries.ARMOR_MATERIAL` rewrite; brace-depth walker
- `262-repair`: body-aware strip of `renderInventoryText` / `GuiGraphicsExtractor` imports
- Pipeline: re-run `Invoke-Minecraft262CompileRepairPass` after `mcreator-1.21.x` when that pass touches files
- Fixes Mode B leftovers: `HumanoidModel.crouching/riding/young`, `applyEffectTick(ServerLevel,…)`, `EffectRenderingInventoryScreen`

## Where things live

| Role | Path |
|---|---|
| Packaging / GitHub repo | `C:\Users\rmbel\Documents\Codex\2026-08-29\referenced-chatgpt-conversation-this-is-an-4\work\LegacyJavaConverter` |
| Dist artifacts | `...\LegacyJavaConverter\dist\` |
| Installed AppData | `C:\Users\rmbel\AppData\Local\RB-Legacy-Java-Converter` |
| Station tools mirror | `C:\rmblocal_llm\projects\RB-Legacy-Java-Converter\tools` |
| Solved knowledge | `C:\rmblocal_llm\knowledge\Solved_Problems\legacy-java-converter-26.2\` |

## Sensible next work

1. Install Setup **or** unzip Portable; confirm GUI title **v2.10.4**.
2. Mode B re-run gecko_kings 1.21.1 jar with **Compile after convert**; expect installable jar without client gate.
3. When Xbox is up: in-game verify CASE-005 jar on NeoForge 26.2.0.72.

## Do not redo

- Do not claim public GitHub release without publishing Setup + Portable.
- Do not invent a permanent client renderer compile-gate when entity-render-state submit path applies.
- Do not rebuild MedSystem overlay from broken oracle sources.
