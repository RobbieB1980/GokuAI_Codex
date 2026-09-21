# 262r — do not

Anti-patterns proven on CASE-005 / converter 2.10.3–2.10.6. Each one made Mode B rediscover a green-folder leftover.

## Do not put 26.2-universal remaps only on a version-gated residue pass

`mcreator-1.20.1` residue does not run for NeoForge 1.21.x. Encode in `Invoke-Minecraft262CompileRepairPass` (every route + post-MCreator sweep).

## Do not register custom GameRules with static `GameRules.registerBoolean`

Compiles. Crashes at constructMods: `Registry is already frozen` with key `minecraft:game_rule / minecraft:<name>` (no mod namespace). Use `DeferredRegister.create(Registries.GAME_RULE, MODID)` + `new GameRule<>()` + `REGISTRY.register(modEventBus)` + use-site `.get()`. Match MCreator generator-26.1.2. Do not register on `FMLCommonSetupEvent` either.

## Do not gate `registerItemExtensions` stub on `Registries.ARMOR_MATERIAL` rewrite

Armor may already be a static record. The stub must run whenever `getHumanoidArmorModel` / `armorModel.crouching` remains. Use a brace-depth walker (anon class + method + if). Replacement must use real newlines, not literal `` `r`n ``.

## Do not invent a permanent client renderer compile-gate

When primer Entity Render States apply, acid/projectile renderers use `submit(state, PoseStack, SubmitNodeCollector, CameraRenderState)` + `extractRenderState`, mirroring vanilla `ArrowRenderer`. A compile-gate that excludes renderers is interim-only.

## Do not treat `REGISTRY.register("id", FooBlock::new)` as 26.2-safe

If the ctor takes `Properties`, 26.2 requires `registerBlock` / `registerItem` so `Properties.setId` runs before construction. Vineflower multiline `super(Properties.of())`, Door/Stairs/Flower/Liquid/Button extra super-args, armor inner `new Properties()`, and `Outer.Inner::new` all miss a same-line regex.

## Do not leave `#forge:` biome tags in datapacks

`Tags.Biomes.IS_CAVE` is `c:is_cave`. World create fails with `Unbound tags … biome: [forge:is_cave]`. Rewrite after asset restore.

## Do not parent spawn eggs at `minecraft:item/template_spawn_egg`

That model is removed in 26.2. Restore a two-layer 1.21.1 template under the **mod** namespace. Unprefixed `item/` / `block/` parents must become `minecraft:item/` / `minecraft:block/`.

## Do not assume `Mob.createMobAttributes()` is enough for `TemptGoal`

`TemptGoal.canUse` reads `Attributes.TEMPT_RANGE` (default 10). `Animal.createAttributes()` includes it; `Mob.createMobAttributes()` does not. Tick crash: `Can't find attribute minecraft:tempt_range`.

## Do not claim GitHub/installer 2.10.6 from tools-only remaps

Product GUI `version.txt` can still read 2.10.5 until Setup/Portable rebuild. Tools remap and product version are separate.

## Do not validate with ambient/source Java first

NeoForge 26.2 destination JDK is **25**. Ambient `JAVA_HOME` is often Java 8. Bare `gradlew` under Java 8 yields `Gradle requires JVM 17+ ... configured to use JVM 8` — that is a wrong-JDK mistake, not a mod compile error. Use `Build-WithDestinationJava.ps1` / `Invoke-GradleBuildWithRequiredJava` and `org.gradle.java.home` before the first build.

## Do not construct ItemStack in static initializers or FMLClientSetup on 26.2

`ItemStack` ctor needs bound Holder components. Static `new ItemStack(Items.*, n)` and FMLClientSetup deferred config that materializes stacks crash with `Components not bound yet`. Use string item ids + lazy load. **ID:** `mc-262r-itemstack-components-bound`
