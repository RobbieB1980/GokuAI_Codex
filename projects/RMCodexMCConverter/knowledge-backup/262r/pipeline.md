# 262-repair pipeline

Converter: `Convert-Forge1201-ToNeoForge262.ps1` (Legacy Java Converter 2.10.6 tools).

262-repair is **not** a version-gated residue pass. It runs on every route so NeoForge **1.21.x** Mode B gets the same remaps as 1.20.1.

## Order (relevant slice)

```
ExactPrimer
NeoForge 26 API
Entity/item subpackage remap
→ Invoke-Minecraft262CompileRepairPass          # first sweep (includes GameRules DeferredRegister)
Optional integration exclude
DFU / record / mixin
SubmitCustomGeometry
MCreator 1.21.x → 26.2
→ Invoke-Minecraft262CompileRepairPass          # ONLY if mcreator-1.21.x touched files (idempotent leftover sweep)
MCreator 1.20.1 residue                         # gated; do NOT put 26.2-universal remaps only here
Registry template
→ Invoke-BlockItemIdPass
GeckoLib / mod-entry / event-bus
Solved overlays
Restore assets/data
→ Invoke-ForgeConventionTagRewritePass          # after restore (JSON tags live in assets)
Client item stubs
→ Invoke-Minecraft262ItemModelPass
```

## Why the post-MCreator sweep exists (2.10.5)

`applyEffectTick(ServerLevel,…)` and `renderInventoryText` strip lived only in `Invoke-McreatorForge1201ResiduePass` (profile gate `mcreator-1.20.1`). NeoForge 1.21.x jobs enable `mcreator-1.21.x` and skip that residue pass. Installer Mode B regenerated the same 9 potion errors while a hand-patched folder stayed green.

**Rule:** any remap that must fire for 1.21.x belongs in `Invoke-Minecraft262CompileRepairPass` (every route + post-MCreator sweep). Residue may keep an idempotent copy, never the only copy.

`registerItemExtensions` stub must be **ungated** from the `Registries.ARMOR_MATERIAL` rewrite. If armor is already a static record, a gated stub skips and `HumanoidModel.crouching/riding/young` remain.

## Asset passes run after Java

Convention-tag rewrite and spawn-egg item models must run **after** `Restore-ModAssets`. Decompiled trees are often Java-only; biome modifiers and `models/item/*.json` appear only after jar/asset restore.
