# CASE-008: Woodlands 2.0, NeoForge 1.21.1 to 26.2

Status: verified by a complete Java 25 `gradlew build`, successful in-game world creation, dimension entry, and located structure generation; packaged output was `woodlands-2.0+mc26.2-neoforge.jar`.

## Hardened fixes

- Renderer migration: parameterize `HumanoidMobRenderer` and `HumanoidModel` with `HumanoidRenderState`, implement `createRenderState`, and use `ArmorModelSet` plus the equipment renderer.
- Dimension migration: remove the obsolete client `DimensionSpecialEffects` registration helper while preserving the actual dimension definition. Express the 26.2 environment through `dimension_type` data, including `attributes`, `skybox`, and `has_ender_dragon_fight`.
- Portal migration: move `BlockUtil` to `net.minecraft.util`, replace `DimensionTransition` with `TeleportTransition`, use the eight-argument `updateShape`, pass mutable `LevelAccessor` explicitly for portal creation, and use `getMinY`/`getMaxY`.
- Villager trade migration: replace removed Java `BasicItemListing`/`VillagerTradesEvent` registration with `villager_trade` JSON and the appropriate `tags/villager_trade` entry.
- Entity loot migration: call `super.dropCustomDeathLoot(serverLevel, source, recentlyHitIn)` and retain `this.level()` for spawning.
- Item durability migration: call `ItemStack.hurtAndBreak(amount, entity, InteractionHand)` directly; do not call removed `LivingEntity.getSlotForHand`.
- Biome codec migration: convert an empty legacy `carvers` object to an empty array.
- Tree codec migration: add the required rule-based `below_trunk_provider`, reusing the configured dirt provider to preserve custom terrain material.
- Noise-router migration: add the required `preliminary_surface_level` density function and validate the resulting file with a strict JSON parser.
- Structure migration: project all five legacy fixed-height jigsaw starts to `WORLD_SURFACE_WG`. Use `raw_generation` for the ruined fortress and wooden statue because the 26.2 surface phase located but did not materialize those pieces in this ceiling-style dimension.
- Build reliability: retry exactly once only when Gradle fails with an `AccessDeniedException` on a cached `.jar`; do not delete the shared cache.

## Preserved behavior

- The `woodlands:wood_land` dimension and its data remain present.
- The custom oak-plank portal frame, custom portal block, POI, ash animation, sound, and zero transition time remain present.
- The toolsmith trade remains one Wood Land item for 24 emeralds, maximum use 1, XP 5, reputation discount 0.05.
- The Wood Land biome, oak-plank tree substrate, custom noise terrain, and world-creation path remain operational.
- All original structure NBT assets, template pools, spacing, separation, and salts remain intact; only their 26.2 placement phase and surface projection were migrated.
- Every original `assets/` and `data/` entry remains present. Additions are limited to required 26.2 item definitions and data-driven trade/tag files.

## Exact evidence

- Verified overlay: `lib/overlays/woodlands/1.21.1.zip`
- Solved index entry: `CASE-008-woodlands-1.21.1`
- Target source artifact: `build/moddev/artifacts/minecraft-patched-26.2.0.72-sources.jar`
- Build result: `C:/Projects/codex_projects/Woodlands/woodlands-2.0-neoforge-1.21.1-26.2/KAT_PASS_RESULT.md`

The exact overlay is mod-scoped. Generic converter rewrites are limited to mechanically safe signatures and semantic JSON migrations; complex portal and dimension behavior is supplied by the runtime-verified overlay rather than guessed across unrelated mods.
