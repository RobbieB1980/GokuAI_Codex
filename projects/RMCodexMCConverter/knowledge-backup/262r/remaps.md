# 262r — compile remaps (Invoke-Minecraft262CompileRepairPass)

Target: NeoForge **26.2**. Detection is source-cue, not version-gated. Confirm APIs against exact 26.2 physical source before inventing a new variant.

Related sibling passes are listed at the end. GameRules DeferredRegister is invoked from this pass.

## Packages / types

| ID | Detect | Target |
|---|---|---|
| `mc-262r-minecart-package` | `world.entity.vehicle.AbstractMinecart` (+ Minecart*) | `world.entity.vehicle.minecart.*` |
| `mc-262r-boat-package` | `world.entity.vehicle.AbstractBoat` / `Boat` / `Raft` | `world.entity.vehicle.boat.*` |
| `mc-262r-feline-model-split` | `client.model.FelineModel` / `@Mixin(FelineModel)` | 26.1 split: `AbstractFelineModel`; `createBodyMesh`→`AdultFelineModel`; `setupAnim` mixin→`{Adult,Baby}FelineModel` (see `shards/feline-minecart-packages.md`) |
| `mc-262r-mixin-descriptor-slash` | mixin `Lnet/minecraft/world/entity/animal/Cat;` | rewrite slash form when FQN remaps (entity subpackage pass) |
| `mc-262r-mixin-this-instanceof` | `@Mixin` + `this instanceof T` | `(Object) this instanceof T` |
| `mc-262r-fog-package` | `net.minecraft.client.renderer.FogRenderer` | `net.minecraft.client.renderer.fog.FogRenderer` |
| `mc-262r-interaction-result` | `world.item.context.InteractionResult` / `world.item.InteractionResult` | `net.minecraft.world.InteractionResult` |
| `mc-262r-interaction-result` | `InteractionResultHolder<ItemStack>` | `InteractionResult` (Item.use returns InteractionResult) |
| `mc-262r-sound-getvalue` | `BuiltInRegistries.SOUND_EVENT.get(` | `.getValue(` (Holder/Optional → T) |
| `mc-262r-mobeffects-rename` | `MobEffects.MOVEMENT_SLOWDOWN` / `MobEffects.JUMP` (not JUMP_*) | `SLOWNESS` / `JUMP_BOOST` |

## Items / tools / armor

| ID | Detect | Target |
|---|---|---|
| `mc-262r-spawn-egg-item` | `new DeferredSpawnEggItem(type, bg, fg, new Properties())` | `new SpawnEggItem(new Properties().spawnEgg(type.get()))`; prefer `REGISTRY.registerItem(..., p -> new SpawnEggItem(p.spawnEgg(...)))` |
| `mc-262r-toolmaterial` | `private static final Tier TOOL_TIER = new Tier() { … }` | `ToolMaterial` record + `super(new Properties().sword(TOOL_MATERIAL, atk, atkSpeed))`. Vineflower bare `F` attack-speed → `-0.8F` |
| `mc-262r-armor-record` | `Registries.ARMOR_MATERIAL` + `new ArmorMaterial(` / `new Layer(Identifier.parse` | Static 8-arg equipment `ArmorMaterial(durability, Map.of(ArmorType…), enchant, sound, toughness, knockback, repair TagKey, EquipmentAssets ResourceKey)`. Drop `RegisterEvent` armor register. Field is `ArmorMaterial`, not `Holder<ArmorMaterial>` |
| `mc-262r-item-extensions-stub` | `registerItemExtensions` + `getHumanoidArmorModel` / `armorModel.crouching` | Empty `registerItemExtensions(RegisterClientExtensionsEvent)` via brace-depth walk. Ungated. Real newlines. `HumanoidModel.crouching/riding/young` removed |
| `mc-262r-potion-named` | `new Potion(new MobEffectInstance[]{ … })` | `new Potion("registryname", instance)` |

## Fluids / fog / capabilities

| ID | Detect | Target |
|---|---|---|
| `mc-262r-fluid-capability` | `Capabilities.FluidHandler` / `FluidBucketWrapper` | `Capabilities.Fluid.ITEM` (`ResourceHandler`). Stub `registerCapabilities` body — wrapper type no longer matches |
| `mc-262r-fog-data` | `FogShape` / `FogRenderer.FogMode` / `modifyFogRender` / `modifyFogColor` | `modifyFogColor(..., Vector4f)` void mutator; `modifyFogRender(Camera, FogEnvironment, float, float, FogData)` |

## Entities / AI / projectiles

| ID | Detect | Target |
|---|---|---|
| `mc-262r-boss-uuid` | `new ServerBossEvent(this.getDisplayName(),` | `new ServerBossEvent(UUID.randomUUID(), this.getDisplayName(),` |
| `mc-262r-ai-step-level` | `customServerAiStep()` | `customServerAiStep(ServerLevel level)` + `super.customServerAiStep(level)` |
| `mc-262r-arrow-inground` | `this.inGround` on `AbstractArrow`; `EntityType.Builder.of(FooAcidEntity::new` | `this.isInGround()`; `Builder.<FooAcidEntity>of` when ctor is `EntityType<? extends AbstractArrow>` |
| `mc-262r-entity-type-tag` | `.getType()` newline `.is(` | `.getType().builtInRegistryHolder().is(` (multiline-safe) |
| `mc-262r-thrown-splash` | `new AbstractThrownPotion(EntityTypes.POTION,` | `new ThrownSplashPotion(EntityTypes.SPLASH_POTION,` |
| `mc-262r-gamerules-serverlevel` | `world.getLevelData().getGameRules()` / `((Level)world).getGameRules()` | `world instanceof ServerLevel _sl && _sl.getGameRules().get(...)` |
| `mc-262r-tempt-range` | `new TemptGoal` + `createAttributes()` without `TEMPT_RANGE` | `builder = builder.add(Attributes.TEMPT_RANGE, 10.0);` before `return builder` |

`getLevel()` → `level()`. `spawnAtLocation(level, …)` needs `(ServerLevel) this.level()`. Vineflower swim `LookControl`: `Entity.this` where `getXRot()` was intended.

EntityType builder `.build(registryname)` string → `ResourceKey.create(Registries.ENTITY_TYPE, Identifier.parse(modid + ":" + registryname))`.

`Ingredient.of(new ItemStack[]{ new ItemStack(Items.X) })` → `Ingredient.of(Items.X)`.

## Client render (primer 1.21.2 Entity Render States)

| ID | Detect | Target |
|---|---|---|
| `mc-262r-hierarchical-model` | `HierarchicalModel` / nested `AnimatedModel` | Super uses the real model type; delete animator inner class |
| `mc-262r-rendertobuffer-final` | `void renderToBuffer(PoseStack` override | Delete (method is final) |
| `mc-262r-create-render-state` | `extends MobRenderer` / `EntityRenderer` without `createRenderState()` | Return `new LivingEntityRenderState()` |
| `mc-262r-submit-projectile` | `*Renderer.java` extends `EntityRenderer<` still on `public void render(` + cutout/buffer | Rewrite to ArrowRenderer shape: `submit(LivingEntityRenderState, PoseStack, SubmitNodeCollector, CameraRenderState)` + `extractRenderState` setting xRot/yRot. Model `setupAnim(LivingEntityRenderState)` |
| glow layers | `this.addLayer(new RenderLayer<` entity-typed | Drop (RenderState generics) |
| `getArmorTexture(..., Layer, ...)` | old Layer arg | Drop (equipment assets) |

Projectile submit skeleton (vanilla `ArrowRenderer` pattern):

```java
public class FooAcidRenderer extends EntityRenderer<FooAcidEntity, LivingEntityRenderState> {
   public LivingEntityRenderState createRenderState() { return new LivingEntityRenderState(); }
   public void extractRenderState(FooAcidEntity entity, LivingEntityRenderState state, float partialTicks) {
      super.extractRenderState(entity, state, partialTicks);
      state.xRot = entity.getXRot(partialTicks);
      state.yRot = entity.getYRot(partialTicks);
   }
   public void submit(LivingEntityRenderState state, PoseStack poseStack, SubmitNodeCollector buffer, CameraRenderState camera) {
      poseStack.pushPose();
      poseStack.mulPose(Axis.YP.rotationDegrees(state.yRot - 90.0F));
      poseStack.mulPose(Axis.ZP.rotationDegrees(90.0F + state.xRot));
      this.model.setupAnim(state);
      buffer.submitModel(this.model, state, poseStack, TEXTURE, state.lightCoords, OverlayTexture.NO_OVERLAY, state.outlineColor, null);
      poseStack.popPose();
      super.submit(state, poseStack, buffer, camera);
   }
}
```

## MobEffect (must live in 262-repair, not only 1.20.1 residue)

| ID | Detect | Target |
|---|---|---|
| `mc-262r-effect-tick-level` | `applyEffectTick(LivingEntity, int)` / `isDurationEffectTick` | `boolean applyEffectTick(ServerLevel level, LivingEntity, int)` returning true; `shouldApplyEffectTickThisTick`; `super.applyEffectTick(level, …)` |
| `mc-262r-effect-tick-level` | `renderInventoryText(...)` | Delete method; drop unused `EffectRenderingInventoryScreen` / `GuiGraphicsExtractor` imports (body-unused only) |

## Custom GameRules (called from 262-repair)

See [crashes.md](crashes.md) §1. **Never** static `GameRules.registerBoolean` / `registerInteger` in `<clinit>` or `FMLCommonSetupEvent`.

| ID | Detect | Target |
|---|---|---|
| `mc-262r-gamerules-deferred` | `class *GameRules` + `GameRules.registerBoolean` / `BooleanValue.create` | `DeferredRegister.create(Registries.GAME_RULE, MODID)` + `new GameRule<>()` + `REGISTRY.register(modEventBus)` + use-site `.get()` |
| nested leftovers | `import …GameRules.BooleanValue/Key/Category` | Strip nested imports |

## Sibling passes (not inside the Java compile loop)

| ID | Pass | Detect | Target |
|---|---|---|---|
| `mc-262r-block-item-id` | `Invoke-BlockItemIdPass` | no-arg ctor `super(Properties.of())` / `new Properties()`; `REGISTRY.register("id", Foo::new)` when ctor takes Properties | Ctor takes `Properties`; `registerBlock` / `registerItem`. Two-pass so rewritten ctors are on disk before method-ref conversion. `Outer.Inner::new` counts |
| `mc-262r-convention-tags` | `Invoke-ForgeConventionTagRewritePass` | `#forge:` / `forge:is_*` in assets+Java | `#c:` / `c:is_*`. After asset restore. Copy `data/forge/tags` → `data/c/tags` |
| `mc-262r-template-spawn-egg` | `Invoke-Minecraft262ItemModelPass` | parent `minecraft:item/template_spawn_egg` or unprefixed `item/` `block/` | Mod-namespace two-layer template; `minecraft:` parents |

## Easy Mob Farm / handwritten NeoForge 1.21.4 leaf wave (2026-09-05)

Open the matching **shard** instead of inventing. Full tables live under `shards/`.

| ID | Shard | Summary |
|---|---|---|
| `mc-262r-value-io-be` / `mc-262r-value-io-entity-load` | [shards/value-io.md](shards/value-io.md) | ValueInput/Output; TagValue*; no BE `level()` |
| `mc-262r-map-entry-getkey` | [shards/map-entry-accessors.md](shards/map-entry-accessors.md) | `entry.property/value` → `getKey/getValue` |
| `mc-262r-entitytype-bystring` | [shards/entity-type-lookup.md](shards/entity-type-lookup.md) | `EntityType.byString` → BuiltInRegistries |
| `mc-262r-flying-mob-removed` | [shards/flying-mob-removed.md](shards/flying-mob-removed.md) | FlyingMob/FlyingAnimal gone |
| `mc-262r-ber-render-state` | [shards/block-entity-render-state.md](shards/block-entity-render-state.md) | BER `<T,S>` + submit |
| `mc-262r-tooltip-consumer` | [shards/tooltip-consumer.md](shards/tooltip-consumer.md) | Consumer tooltips + GuiGraphicsExtractor |
| `mc-262r-itemhandler-block-stub` | [converter/capability-stub.md](converter/capability-stub.md) | Multiline capability stub |
| `mc-262r-dep-dual-pull` | [converter/dual-deps.md](converter/dual-deps.md) | Source + 26.2 Modrinth jars |
| (misc leaf IDs) | [shards/misc-26.2-leaf.md](shards/misc-26.2-leaf.md) | CustomData, SpawnEgg, VillagerData, cubemob, … |

## Evidence

- CASE-005: `Solved_Problems/legacy-java-converter-26.2/CASE-005-gecko-kings-1.21.1.md`
- Easy Mob Farm: `C:\Projects\Easy Mod Farm\easy_mob_farm-neoforge-1.21.4-10.3.0-26.2` (compile-green jar `easy_mob_farm-10.3.0+mc26.2-neoforge.jar`)
- Easy Mob Farm re-run repair: `C:\Projects\Easy Mod Farm\tet\test-26.2` → `build/libs/easy_mob_farm-1.0.0+mc26.2-neoforge.jar` (2026-09-05; encoded gametest-always-exclude + cubemob/frog + FlyingMob + modlauncher + Item.Properties ctor dedupe)
- MCreator generator-26.1.2 is the nearest official GameRule/registerBlock shape (no `generator-26.2` yet)
- Primer 1.21.2 Entity Render States for `submit` / `extractRenderState`
- Exact target APIs: `Exact_Version_Sources/NeoForge/26.2` and `Minecraft_Java_Server_Client/26.2/client.jar` (or MCP `grep_physical_source`)
