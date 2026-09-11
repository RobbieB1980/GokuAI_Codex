# Dependency pipeline

The converter cannot magically make **every** Forge/NeoForge mod a loadable 26.2 jar. Mixins, coremods, and huge APIs still need hand work. It **does** now:

1. Read what the mod actually depends on
2. Download the **detected source-version** jar and the **destination 26.2** jar when Modrinth has them
3. Wire the 26.2 jar onto the compile classpath (`libs/`)
4. Keep the source-version jar for API comparison (`libs-source/`)
5. Decompile + convert required mods that still need a 26.2 port (from the detected source version, not a hardcoded 1.20.1)

## Where dependencies are read

| Source | Example |
|--------|---------|
| `META-INF/mods.toml` / `neoforge.mods.toml` | `[[dependencies.mymod]] modId="geckolib"` |
| `build.gradle` | `implementation fg.deobf("software.bernie.geckolib:...")` |
| `META-INF/jarjar/metadata.json` | Forge jar-in-jar |
| Java imports | `software.bernie.geckolib`, `mezz.jei`, … |
| `detected-dependencies.json` | Written by the jar decompiler |

`minecraft`, `forge`, and `neoforge` are skipped.

## Dual-version pull (mandatory)

For each detected dependency (including optional / import-detected soft deps such as JEI):

| Artifact | Destination | Purpose |
|----------|-------------|---------|
| Source MC version (e.g. 1.21.4) | `libs-source/` + `tools/lib/dep-cache/<version>/` | Evidence for API deltas / Fix-in-Grok |
| Target **26.2** | `libs/` + `tools/lib/dep-cache/26.2/` | Compile + runtime classpath |

If only the source jar exists, it is still saved and reported (`source-downloaded`). Conversion of required deps without a 26.2 official jar uses that source jar.

## Resolution order (per mod id)

1. **Catalog Maven** — GeckoLib 5.5.3, SmartBrainLib 2.0.0, …
2. **Modrinth dual pull** — source version + NeoForge/Forge **26.2**
3. **Convert** — only if the dep is **required** (or `-ConvertOptionalDependencies`) and no 26.2 artifact exists
   - Local jar from `-DependencyJarDir`, source `libs/`, or `run/mods/`
   - Else use the already-downloaded **detected source-version** jar from Modrinth
4. **Gap** — recorded in `DEPENDENCY_REPORT.md`

Never auto-converted (need official 26.2 ports): Architectury, Kotlin for Forge, Flywheel, Create, MixinExtras.

## Soft integrations (JEI / Carry On / …)

- Import detection marks catalog libraries (e.g. `mezz.jei` → `jei`) as required for resolve.
- When a 26.2 jar lands in `libs/`, integration sources under `compat/jei` / `integration/jei` are **kept** and compiled against that jar.
- When no 26.2 jar is available, `Invoke-OptionalIntegrationExcludePass` strips those sources so the leaf mod can still build.

## Output layout

```
mymod-26.2/
  libs/                  destination 26.2 jars (compile classpath)
  libs-source/           detected source-version jars (comparison evidence)
  converted-deps/        recursive 26.2 scaffolds for required mods
  DEPENDENCY_REPORT.md
  detected-dependencies.json
```

Jars are cached in `tools/lib/dep-cache/<minecraft-version>/` so re-runs do not re-download.

## Limits

- Recursive convert uses the same first-pass rewrites. A converted dependency may not compile.
- Default depth is **2**. Raise `-MaxDependencyDepth` only if you accept a long run.
- Optional toml deps still skip **conversion** unless `-ConvertOptionalDependencies`, but official dual downloads are always attempted.
- Put companion jars next to the input (or pass `-DependencyJarDir`) when Modrinth has no matching slug.
