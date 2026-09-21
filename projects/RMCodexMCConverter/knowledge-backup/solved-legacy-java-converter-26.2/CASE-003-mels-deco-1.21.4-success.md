# CASE-003 — Mel's DeCo (mels_deco) 1.21.4 → NeoForge 26.2 (successful build)

## Status

**Completed / installable / in-game verified (2026-08-30).**  
Full `gradlew build` exit 0; versioned JAR produced.  
Loads with NextGen Furniture on NeoForge **26.2.0.72** (JPMS-001 applied).  
Converter release that encodes the full Mel path: **2.0.2**.

## Paths

| Role | Path |
|---|---|
| Original jar | `C:\Users\rmbel\Downloads\1.21.4 Mel's DeCo v1.2.jar` |
| Decompile intake | `C:\Users\rmbel\Downloads\1.21.4 Mel's DeCo v1.2-decompiled` |
| Successful 26.2 output | `C:\Users\rmbel\Downloads\1.21.4 Mel's DeCo v1.2-26.2` |
| Installed mods jar | `%APPDATA%\.minecraft\versions\neoforge-26.2.0.72\mods\mels_deco-1.2+mc26.2-neoforge.jar` |
| Case reports + jar | `cases/mels-deco-1.21.4/` (this folder tree) |

## Detection

- **modId:** `mels_deco`
- **SourceVersion:** `1.21.4`
- **Loader:** `neoforge`
- **Framework:** MCreator
- **Route:** `neoforge-1.21.x`
- **Confidence:** high
- **Applied band:** `BAND-neoforge-1.21.4`
- **Solved index:** `CASE-003-mels-deco-1.21.4`

## Exact primer rules applied (to > 1.21.4 only)

```
baked-model-to-block-state-model, legacy-direction-property,
armor-tool-item-components, removed-block-lifecycle,
block-entity-value-io, legacy-datagen-isolation,
texture-sheet-to-single-quad, game-rules-rewrite,
block-entity-type-constructor, deferred-entity-type-registration,
entity-server-damage, tristate-minecraft-util, projectile-arrow-package
```

Primer chain policy: destinations **strictly after** detected source (never equal/below).  
Typical ExactPrimer touch count on Mel: **~479** units (not 1).

## Key automated solutions proven on this mod

1. **ArmorItem / SwordItem removed (1.21.5)** → `Item` + `properties.humanoidArmor` / `properties.sword`.
2. **TextureSheetParticle → SingleQuadParticle** (sprite ctor + `getLayer` + `RandomSource` provider).
3. **TriState** package → `net.minecraft.util.TriState`.
4. **GUI extract pipeline** — drop `RenderSystem` blend/color; blit with `RenderPipelines.GUI_TEXTURED`; `drawString` → `text`; `ClientPacketDistributor.sendToServer` (keep `PacketDistributor.sendToPlayer` import).
5. **CHAIN color-collection bug** — word-boundary `Blocks.CHAIN` / `Items.CHAIN` so `CHAINSAW` is not mangled to `IRON_CHAINSAW`.
6. **GameProfile.id()**, Level weather methods, EquipmentSlot armor/hand helpers.
7. **CompoundTag Optional** accessors (`getBooleanOr` / `getStringOr` / `getDoubleOr` / `getIntOr`) including `getPersistentData()`.
8. **BlockEntity.loadWithComponents** → `TagValueInput.create(ProblemReporter.DISCARDING, registries, tag)`.
9. **CommandSourceStack** permission int → `LevelBasedPermissionSet` (match `_level\w*`, including `_levelx` / `_levelxxxxxx`).
10. **Switch expressions** — strip illegal `yield ...; break;`.
11. **Item APIs** — `hurtEnemy` void (strip leftover boolean returns); `inventoryTick(ServerLevel, EquipmentSlot)` with real 4th-arg capture (never literal `$4`); armor worn via `List.of(getItemBySlot HEAD/CHEST/LEGS/FEET)`.
12. **Legacy item models** — `ItemOwner` + `bake(BakingContext, Matrix4fc)`; ConditionalItemModelProperty uses `asLivingEntity()`.
13. **JPMS-001** — do not ship unused shared `rb.legacy.converter.compat`; any `Legacy262Compat` must be `rb.legacy.converter.compat.<modId>`.

## Build / in-game proof

- `COMPILE_REPORT`: exit 0 (deprecation warnings only)
- Installable JAR: `mels_deco-1.2+mc26.2-neoforge.jar` (~13.1 MB)
- Target: Minecraft 26.2 / NeoForge 26.2.0.72 / GeckoLib 5.5.3 (not required by this mod)
- **In-game:** Mel + NextGen load together (user confirmed 2026-08-30)
- Converter: **RB Legacy Java Converter 2.0.2**

## Agent takeaway

When converting `mels_deco` (or similar MCreator NeoForge **1.21.4** cosmetics/furniture jars):

1. Detect `1.21.4` → route `neoforge-1.21.x` + band `BAND-neoforge-1.21.4`.
2. Expect ExactPrimer to touch hundreds of units (armor/particles/lifecycle), not 1.
3. Expect Mcreator1218 GUI/API + NeoForge26 API wave (ValueInput, permissions, Optional NBT, ItemOwner).
4. Run station/AppData tools **2.0.2+** with `-Compile` / `-NeoVersion 26.2.0.72`.
5. Treat this case folder as the 1.21.4 MCreator reference shape.
6. Smoke-test in-game after packaging (especially with other converted mods + JEI).
