# REN-004 — Mel's DeCo 1.21.4 mechanical rules (encoded in converter)

## Proven on

`mels_deco` NeoForge **1.21.4** → NeoForge **26.2.0.72** full `gradlew build` + **in-game verified** with NextGen (converter **2.0.2**, 2026-08-30).

## Primer / ExactPrimer rule IDs

| Rule ID | Transition | Mechanical effect |
|---|---|---|
| `armor-tool-item-components` | 1.21.4→1.21.5 | `ArmorItem`/`SwordItem` → `Item` + `humanoidArmor`/`sword` |
| `removed-block-lifecycle` | 1.21.4→1.21.5 (+ later) | `onRemove`→`affectNeighborsAfterRemoval`; `hasPostProcess` 3-arg→`emissiveRendering(bs->)`; `entityInside` + effect applier; `onDestroyedByPlayer` + `ItemStack toolStack` |
| `block-entity-value-io` | 1.21.5→1.21.6 | `loadAdditional`/`saveAdditional` ValueInput/Output; ContainerHelper 2-arg |
| `texture-sheet-to-single-quad` | 1.21.8→1.21.9 | `TextureSheetParticle`→`SingleQuadParticle` |
| `game-rules-rewrite` | 1.21.10→1.21.11 | `GameRules` package + `RULE_*`→new keys + `get()` |
| `tristate-minecraft-util` | 1.21.11→26.1 / 26.1→26.2 | NeoForge TriState → `net.minecraft.util.TriState` |
| `projectile-arrow-package` | same | Arrow/Trident package moves |

## NeoForge-26-api / MCreator-1.21.x extras (Mel-proven)

- GUI: strip `RenderSystem` blend/color; `RenderPipelines.GUI_TEXTURED`; `text()`; `ClientPacketDistributor`
- `GameProfile.id()`; Level `isRaining`/`isThundering`
- `getType().builtInRegistryHolder().is(tag)`
- Armor slot / hand EquipmentSlot rewrites
- CompoundTag `*Or` accessors; `getPersistentData().getBooleanOr/getStringOr/...`; `TagValueInput` for `loadWithComponents(tag, registryAccess)`
- `Vec2.ZERO, _level\w*, 4` → `LevelBasedPermissionSet.OWNER` (must match `_levelx` / `_levelxxxxxx`, not only exact `_level`)
- `yield ...; break;` cleanup
- Item `hurtEnemy` void (strip leftover `return true/false`); `inventoryTick` ServerLevel + EquipmentSlot (capture 4th arg — never emit literal `$4`); armor worn via `List.of(getItemBySlot HEAD/CHEST/LEGS/FEET)`
- Legacy item model `ItemOwner` + `bake(..., Matrix4fc)`; ConditionalItemModelProperty uses `entity.asLivingEntity()`
- PacketDistributor: keep `sendToPlayer` import; rewrite only bare `PacketDistributor.sendToServer` (avoid `ClientClientPacketDistributor`)
- Color collection: `\bBlocks.CHAIN\b` / `\bItems.CHAIN\b` only (never mangling `CHAINSAW`)
- **JPMS-001:** never leave unused shared `rb.legacy.converter.compat`; Mel's final jar has zero `rb/` entries. When `Legacy262Compat` is required, package is `rb.legacy.converter.compat.<modId>`.
- **Converter 2.0.2:** above API wave encoded in `Invoke-NeoForge26ApiRewritePass` + `Invoke-Mcreator1218ToNeoForge262Pass` (+ residue mirror). Helper: `tools/_apply_mel_262_api_wave.ps1`.

## Policy reminder

`Get-PrimerMigrationChain` must only include transitions whose **destination is strictly after** the detected source.
