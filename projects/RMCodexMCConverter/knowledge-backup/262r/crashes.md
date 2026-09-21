# 262r — in-game crash ladder (NeoForge 26.2)

Compile-green jars still fail at load/play. Encode each leftover in 262-repair (or the named sibling pass) so Mode B does not rediscover it.

Proven on CASE-005 `gecko_kings_avp_mod` against **NeoForge 26.2.0.72**, 2026-09-04.

## 1. constructMods — frozen GAME_RULE registry

**Log:** `Failed to register automatic subscribers. ModID: gecko_kings_avp_mod`  
**Cause:** `IllegalStateException: Registry is already frozen (trying to add key ResourceKey[minecraft:game_rule / minecraft:spawnHellishXenomorphs])`  
**From:** `GeckoKingsAvpModModGameRules.<clinit>` → `GameRules.registerBoolean`

2.10.5 turned MCreator setup-event `GameRules.register` into static vanilla `registerBoolean`. That writes `BuiltInRegistries.GAME_RULE` after freeze and namespaces as `minecraft:`.

**Target shape (MCreator 26.1.2):**

```java
public static final DeferredRegister<GameRule<?>> REGISTRY =
    DeferredRegister.create(Registries.GAME_RULE, MODID);

public static final DeferredHolder<GameRule<?>, GameRule<Boolean>> SPAWN_HELLISH =
    registerBoolean("spawnHellishXenomorphs", GameRuleCategory.MOBS, false);

// supplier: new GameRule<>(category, GameRuleType.BOOL, BoolArgumentType.bool(),
//   GameRuleTypeVisitor::visitBoolean, Codec.BOOL, b -> b ? 1 : 0, value, FeatureFlagSet.of())

// mod ctor: FooModGameRules.REGISTRY.register(modEventBus);
// use site: FooModGameRules.SPAWN_HELLISH.get()
```

**Pass:** `Invoke-Minecraft262CustomGameRuleDeferredRegister` (from 262-repair).  
**ID:** `mc-262r-gamerules-deferred`

## 2. RegisterEvent — Block/Item id not set

**Cause:** `Block id not set` (`PathogenVialBlock.<init>`) and `Item id not set` (`XenomorphChitinArmorItem$Helmet`).  
**Why:** 26.2 requires `Properties.setId` before construction. `DeferredRegister.Blocks.registerBlock` / `Items.registerItem` inject it. No-arg ctors that call `Properties.of()` / `new Item.Properties()` NPE.

Same-line regex misses:

- Vineflower multiline `super(Properties.of())`
- Extra super-args: Door / Stairs / Flower / LiquidBlock / Button
- Armor inner `new Properties()`
- Method-refs `Outer.Inner::new` (not `Type::new`)

**Fix:** two-pass — rewrite no-arg ctors to take `Properties`, then convert `REGISTRY.register("id", Foo::new)` → `registerBlock` / `registerItem` when the ctor takes Properties. Custom `registerBlock(String, Supplier<T>)` helpers become `Function<Properties, T>` (REG-001).

`mels_deco:empty_basket` unbound in the same RegisterEvent round can be cascade after gecko_kings fails BLOCK registration.

**Pass:** `Invoke-BlockItemIdPass`. **ID:** `mc-262r-block-item-id`

## 3. World create — unbound `#forge:` biome tag

**Cause:** `Unbound tags in registry … biome: [forge:is_cave]`  
**From:** `data/.../neoforge/biome_modifier/xenomorph_boiler_biome_modifier.json` `"biomes": "#forge:is_cave"`

NeoForge 26.2 `Tags.Biomes.IS_CAVE` = `Identifier.fromNamespaceAndPath("c", name)` → `c:is_cave`.

**Fix after asset restore:** `#forge:` → `#c:`; bare `forge:is_*` → `c:is_*`; copy `data/forge/tags` → `data/c/tags` if present.

mels_deco `minecraft:chain` / `minecraft:potion` tag misses were logged non-fatal on this instance.

**Pass:** `Invoke-ForgeConventionTagRewritePass`. **ID:** `mc-262r-convention-tags`

## 4. Creative menu — missing `template_spawn_egg`

**Log:** `Missing block model: minecraft:item/template_spawn_egg`  
**Look:** purple/black tiles. Chitin/tool textures can still be present; gecko_kings tab is ~61 spawn eggs.

26.2 removed vanilla `minecraft:item/template_spawn_egg`. Restore a 1.21.1 two-layer generated model **in the mod namespace**:

```json
{
  "parent": "minecraft:item/generated",
  "textures": {
    "layer0": "MODID:item/spawn_egg",
    "layer1": "MODID:item/spawn_egg_overlay"
  }
}
```

Rewrite egg parents to `MODID:item/template_spawn_egg`. Namespace unprefixed `"item/…"` / `"block/…"` parents to `minecraft:`. Converter ships `tools/lib/client-items/spawn_egg.png` + `spawn_egg_overlay.png`.

Spawn eggs may share an uncolored two-layer look until per-egg tints are restored (`DeferredSpawnEggItem` colors were stripped).

**Pass:** `Invoke-Minecraft262ItemModelPass`. **ID:** `mc-262r-template-spawn-egg`

## 5. Server tick — missing `minecraft:tempt_range`

**Crash:** `crash-2026-09-04_18.42.31-server.txt`  
**Cause:** `IllegalArgumentException: Can't find attribute minecraft:tempt_range` while ticking `gecko_kings_avp_mod:chestburster` (`ChestbursterEntity`).

`TemptGoal.canUse` reads `Attributes.TEMPT_RANGE`. Vanilla default is **10**. `Animal.createAttributes()` adds it; MCreator `Mob.createMobAttributes()` does not.

**Fix:** if the entity constructs `new TemptGoal` and `createAttributes()` has no `TEMPT_RANGE`, inject:

```java
builder = builder.add(Attributes.TEMPT_RANGE, 10.0);
```

before `return builder`. CASE-005: 12 chestburster variants (Chestburster, Burster, Predalien, Runner, Royal, Spitter + Hellish/Red counterparts). If another mob ticks a similar goal without the attribute, the next crash names it — apply the same inject.

**Pass:** 262-repair. **ID:** `mc-262r-tempt-range`

## 6. Client setup — ItemStack before components bound

**Crash:** `crash-2026-09-05_12.11.12-client.txt` (Easy Mob Farm CASE-006)  
**Log:** `NullPointerException: Components not bound yet` → `ItemStack.<init>` → `MobFarmBonusConfig.<clinit>`  
**Trigger:** `FMLClientSetupEvent.enqueueWork` → deferred config → static `new ItemStack(Items.*, n)`

**Fix:** string defaults in static maps; no ItemStack on FMLClientSetup; lazy `ensureRegistered()` on first use / ServerStarting.

**Shard:** [shards/itemstack-components-bound.md](shards/itemstack-components-bound.md)  
**ID:** `mc-262r-itemstack-components-bound`

## 7. Mob farm GUI — entity ID before assignment

**Crash:** `crash-2026-09-05_13.13.54-client.txt` (Easy Mob Farm CASE-006)  
**Cause:** `IllegalStateException: Tried to access entity ID before ID assignment`  
**Path:** `MobFarmScreen` → `ScreenHelper.renderEntity` → `InventoryScreen.extractEntityInInventoryFollowsMouse` → `ItemModelResolver.updateForLiving` → `Entity.getId()`

GUI preview entities created with `EntityType.create` are never added to the level, so id stays `INVALID_ENTITY_ID` (0). In 26.2 `getId()` throws.

**Fix:** after create, `entity.setId(uniqueNonZero)` (negative counter is fine). Optionally catch in screen helper so preview failures cannot crash the client.

**ID:** `mc-262r-gui-preview-entity-id`
