# REN-001 — NextGen Furniture 1.21.1 semantic overlay

## Symptom

Mechanical rewrites alone leave BER/standalone/client code that cannot safely be regex-ported (submit signatures, standalone models, render states).

## Detection

- `SOURCE_PROFILE.SourceVersion == 1.21.1`
- `mod_id == nextgen_furniture`
- Presence of custom BER types (e.g. `ConsoleRenderer`)

## Solution

Copy overlay tree:

`tools/lib/overlays/nextgen-furniture/1.21.1/src/main/java/...`

Includes `FurnitureModelCompat`, BER/render-state classes, client/mod entry adjustments.

General rules still run; overlay supplies semantic replacements only for this mod+version.

## Verify

- Overlay files present in output (e.g. `FurnitureModelCompat.java`)
- Full `gradlew build` produces `nextgen_furniture-*-mc26.2-neoforge.jar`

## Proven reference

See **[CASE-001](CASE-001-nextgen-furniture-1.21.1-success.md)** — successful Downloads `*-26.2` build archived to:

- `C:\rmblocal_llm\projects\NextgenFurniture-1.21.1-to-26.2-SUCCESS`
- `cases/nextgen-furniture-1.21.1/`

## Runtime note (fixed in 1.5.5-hotfix1)

Overlays must resolve under `tools/lib/overlays/...` (not `tools/overlays/...`), and must be applied **after** rewrite passes so `BlockEntityType` is not mangled into `EntityType.Builder`.

## Note

1.21.11 jars may need a widened overlay gate or separate overlay folder — do not assume 1.21.1 overlay applies automatically.
