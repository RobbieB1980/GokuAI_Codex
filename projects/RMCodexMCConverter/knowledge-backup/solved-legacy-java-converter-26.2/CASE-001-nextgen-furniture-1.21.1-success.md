# CASE-001 — NextGen Furniture 1.21.1 → NeoForge 26.2 (successful build)

## Status

**Completed / installable.** Full `gradlew build` exit 0; versioned JAR produced.

## Paths

| Role | Path |
|---|---|
| Original jar (Downloads) | `C:\Users\rmbel\Downloads\1.21.1-nextgen_furniture_neoforge+1.21.1-0.0.9-beta.jar` |
| Decompile intake | `C:\Users\rmbel\Downloads\1.21.1-nextgen_furniture_neoforge+1.21.1-0.0.9-beta-decompiled` |
| Successful 26.2 output (Downloads) | `C:\Users\rmbel\Downloads\1.21.1-nextgen_furniture_neoforge+1.21.1-0.0.9-beta-26.2` |
| Station project archive | `C:\rmblocal_llm\projects\NextgenFurniture-1.21.1-to-26.2-SUCCESS` |
| Case reports + jar | `cases/nextgen-furniture-1.21.1/` (this folder tree) |

Note: the folder named `*-decompiled` is **intake only**. The successful conversion is the sibling `*-26.2` tree.

## Detection

- **SourceVersion:** `1.21.1`
- **Loader:** `neoforge`
- **Route:** `neoforge-1.21.x`
- **Confidence:** high
- Evidence: preserved profile + `gradle.properties` `source_minecraft_version=1.21.1` + `neoforge.mods.toml` minecraft `[1.21.1]`

## Exact primer rules applied

```
entity-render-state, block-entity-render-state, standalone-model-keys,
baked-model-to-block-state-model, legacy-direction-property,
block-entity-value-io, legacy-datagen-isolation,
block-entity-type-constructor, deferred-entity-type-registration,
entity-server-damage, removed-block-lifecycle
```

## Dependencies

| Mod | Result |
|---|---|
| minecraft / neoforge | platform |
| fusion | **official Modrinth** `fusion-1.3.14-neoforge-mc26.2` (not converted Alexndr) |

## Key automated solutions present in output

1. **REG-001** — `ModBlocks` uses `properties -> new ...` factories (registry-keyed Properties; no `Supplier` + `Properties.of()` crash pattern).
2. **REN-001** — semantic overlay present (`FurnitureModelCompat.java`, BER/client files).
3. **DEP-001** — Fusion official jar under `libs/`.
4. **DET-001** — `SOURCE_PROFILE.json` + `PRIMER_CHANGE_INDEX.md` written from 1.21.1 → 26.2 only.
5. **JPMS-001** — `Legacy262Compat` lives under `rb.legacy.converter.compat.nextgen_furniture` (not the shared parent package).

## Build proof

- `COMPILE_REPORT`: exit 0, 0 error lines
- Installable JAR: `nextgen_furniture-0.0.9-beta+mc26.2-neoforge.jar` (~12.2 MB)
- Java sources in archive: 72; classes were built during conversion

## Agent takeaway

When converting `nextgen_furniture` from **1.21.1**:

1. Detect `1.21.1` → route `neoforge-1.21.x`.
2. Run station tools converter with `-Compile`.
3. Expect overlay + Fusion official + Supplier→Function registry rewrite.
4. Treat this case folder / SUCCESS project as the reference output shape.

Still recommended after packaging: in-game `runClient` smoke test (not recorded in these reports).
