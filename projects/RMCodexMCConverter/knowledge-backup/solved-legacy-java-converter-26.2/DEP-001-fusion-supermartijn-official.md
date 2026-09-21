# DEP-001 — Fusion must be SuperMartijn642 official 26.2

## Symptom

Dependency pipeline converts a wrong “Fusion” jar (e.g. Alexndr Fusion 1.20.1) and may recurse into unrelated libs (simplecorelib). Connected-textures Fusion never resolves correctly.

## Detection

- `neoforge.mods.toml` / `mods.toml` requires `fusion`
- Imports (if any) under `com.supermartijn642.fusion`
- Catalog/modrinth id should be `fusion-connected-textures`

## Solution

- `tools/lib/DependencyCatalog.json` entry: `modId=fusion`, action `official`, modrinth `fusion-connected-textures`
- Bundled cache: `tools/lib/dep-cache/fusion-1.3.14-neoforge-mc26.2.jar`
- Do **not** treat Alexndr Fusion as the same mod

## Verify

`DEPENDENCY_REPORT.md` shows Fusion as official/modrinth download, not `converted-deps` of the wrong lineage.
