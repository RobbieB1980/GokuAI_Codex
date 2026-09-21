# REN-003 — ItemBlockRenderTypes removed

## Symptom

`cannot find symbol: class ItemBlockRenderTypes` and/or cutout furniture renders opaque.

## Solution

1. Collect block ids from `ItemBlockRenderTypes.setRenderLayer(..., ChunkSectionLayer.CUTOUT)`.
2. Remove those calls/imports.
3. Inject `"render_type": "minecraft:cutout"` into matching `assets/*/models/block/*.json` when missing.

Implemented in the mechanical rewrite pass of `Convert-Forge1201-ToNeoForge262.ps1`.
