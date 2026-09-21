# Session continue — RB Legacy Java Converter 2.10.6

**Read this first** when reopening this worktree. Last saved: **2026-09-05**.

## Status (current)

- **Product released as v2.10.6** (Setup + Portable).
- GitHub: https://github.com/RobbieB1980/LegacyJavaConverter/releases/tag/v2.10.6
- Desktop copies: `RB-Legacy-Java-Converter-Setup.exe` + `RB-Legacy-Java-Converter-Portable.zip`
- Packaging commit `4960a8f` on `main`; tag `v2.10.6`.
- CASE-005 **in-game verified** on NeoForge 26.2.0.72; recipe ingredient pass included.
- Install Setup (or unzip Portable) before further conversion testing so GUI title reads **v2.10.6**.

## Sensible next work

1. Install Desktop Setup.exe (or use Portable) and confirm GUI title `v2.10.6`.
2. Continue Mode B conversion testing with `-Compile` on new jars.
3. Optional: relaunch 26.2.0.72 once to confirm gecko recipe ERROR lines are gone after the cleaned jar.

## Do not redo

- Do not put custom game rules on static `GameRules.registerBoolean` / `FMLCommonSetupEvent`.
- Do not put 26.2-universal remaps only on a version-gated residue pass.
- Do not invent a permanent client renderer compile-gate when entity-render-state submit path applies.
- Do not leave recipe ingredients as `{"item":…}` / `{"tag":…}` objects on 26.2.
