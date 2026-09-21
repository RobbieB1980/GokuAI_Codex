# Converter — dual-version dependency pull

**Pass:** `Resolve-AndAcquireDependencies` in `tools/lib/ModDependencyPipeline.ps1`  
**IDs:** `mc-262r-dep-dual-pull`, `mc-262r-dep-source-version`

## Rule

For each detected dependency (toml / gradle / jarjar / **Java import** / detected-json):

| Artifact | Destination | Purpose |
|---|---|---|
| Detected **source** MC version (e.g. 1.21.4) | `libs-source/` + `dep-cache/<version>/` | API comparison evidence |
| Destination **26.2** | `libs/` + `dep-cache/26.2/` | Compile + runtime classpath |

Do **not** hardcode source jar download to `1.20.1`. Use `SourceMinecraftVersion` from `SOURCE_PROFILE` / convert caller.

## Detect

- Catalog library with Modrinth slug (e.g. `jei`)
- Import hit (e.g. `mezz.jei`) or toml/gradle dep

## Target shape

1. `Save-ModrinthVersionToDirs` for source version → `libs-source/`
2. `Save-ModrinthVersionToDirs` for `26.2` → `libs/`
3. Wire target jar via `implementation files('libs/<leaf>')`
4. Report both leaves in `DEPENDENCY_REPORT.md`

Optional deps: still attempt official dual download; skip **conversion** unless `-ConvertOptionalDependencies`.

## Proven

Easy Mob Farm 1.21.4 → 26.2 (2026-09-05):

- `libs-source/jei-1.21.4-neoforge-20.0.0.4.jar`
- `libs/jei-26.2-neoforge-30.30.0.204.jar`
