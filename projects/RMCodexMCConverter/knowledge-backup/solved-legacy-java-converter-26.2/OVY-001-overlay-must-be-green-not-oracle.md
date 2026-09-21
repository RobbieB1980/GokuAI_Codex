# OVY-001 — Solved overlays must be green trees, not broken oracles

## Symptom

Converter log looks healthy:

- DFU repair touched N files
- Overlay applied (`medsystem/1.21.1.zip`, files touched: hundreds)

…but `gradlew build` still fails with the **same** DFU/mixin errors DFU just fixed.

## Root cause

Overlays are applied **last** (after rewrite/DFU passes). If the overlay zip/dir was built from:

- author “oracle” decompile of an official 26.2 jar, or
- a half-migrated tree that still has Vineflower DFU breakage,

then the overlay **overwrites** the repaired sources and reintroduces the bugs.

CASE-004 2.0.3→2.0.4: `LimbConfiguration` in the overlay matched the broken scaffold (`RecordCodecBuilder.create` + `config.limbs`) while the proven green project had `RecordCodecBuilder.<LimbConfiguration>create` + `config.limbs()`.

## Rules for encoding overlays

1. **Source of truth = last green `src/`** that produced `build/libs/*.jar`, not raw oracle decompile.
2. Always include a real **`DELETE.txt`** (paths relative to project root) for units that must not remain:
   - soft-dep Integration classes without classpath jars
   - Vineflower leftover util classes that moved into a required dep
   - broken client shaders / debug mixins that cannot compile on 26.2
3. Keep **`*.mixins.json`** in the overlay and **drop mixin class names** that `DELETE.txt` removes.
4. Prefer **zip** overlays (`lib/overlays/<mod>/<ver>.zip`) to avoid Windows `MAX_PATH` in Setup packaging.
5. After rebuilding an overlay, **reconvert from the original jar** (or re-apply overlay on a fresh scaffold) and require green `gradlew build`.

## How to rebuild (MedSystem pattern)

```powershell
# Green project that already builds:
$green = "...\oldmedsystem-...-26.2"
$stage = "$env:TEMP\overlay-rebuild"
# copy $green\src\main\java (+ mixins.json), write DELETE.txt, zip to:
# tools\lib\overlays\medsystem\1.21.1.zip
```

Then bump converter version, ship Setup, and re-run Mode B on the original input jar.

## Related

- `DFU-001-recordcodecbuilder-validate-mixin.md`
- `INT-001-soft-dep-integration-exclude.md`
- `CASE-004-medsystem-1.21.1.md`
- `REN-001-nextgen-furniture-1.21.1-overlay.md` (same overlay mechanism, different mod)
