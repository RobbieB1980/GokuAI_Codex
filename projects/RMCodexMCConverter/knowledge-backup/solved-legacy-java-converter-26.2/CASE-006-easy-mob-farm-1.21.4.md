# CASE-006 — Easy Mob Farm NeoForge 1.21.4 → 26.2

## Status

**Compile-green / installable jar (2026-09-05)** on converter tools after Fix-in-Grok repair.

- Output: `C:\Projects\Easy Mod Farm\easy_mob_farm-neoforge-1.21.4-10.3.0-26.2`
- Jar: `build/libs/easy_mob_farm-10.3.0+mc26.2-neoforge.jar` (~873 KB)
- Dual deps: `libs/jei-26.2-neoforge-30.30.0.204.jar` + `libs-source/jei-1.21.4-neoforge-20.0.0.4.jar`
- In-game: user testing (not yet recorded here)

## Detection

- SourceVersion **1.21.4**, loader neoforge, handwritten (Framework unknown / not MCreator-primary)
- Route `neoforge-1.21.x`
- Import-detected **jei** (`mezz.jei`) — was missed until SimpleMatch+Escape bug fixed

## Knowledge encoded

All remaps written to category **`262r`** / version **26.2**:

- `converter/dual-deps.md`, `import-detect.md`, `soft-dep-exclude.md`, `fix-in-grok.md`, `capability-stub.md`
- `shards/value-io.md`, `map-entry-accessors.md`, `entity-type-lookup.md`, `flying-mob-removed.md`, `block-entity-render-state.md`, `tooltip-consumer.md`, `misc-26.2-leaf.md`

## Agent takeaway

1. Open `262r` shards matching the error family before inventing.
2. Dual-pull source + 26.2 companion jars; keep `compat/jei` when `libs/*jei*` exists.
3. Fix-in-Grok must open `GROK_REPAIR_PROMPT.md` (path pointer) — never rely on multiline bat args.
