# PKG/REN — Entity & item subpackages (1.21.11 → 26.2)

## Motivating case

`gecko_kings_avp_mod` (NeoForge 1.21.1 → 26.2) failed compileJava with ~300 errors dominated by missing symbols from the **1.21.11 primer** entity package splits, plus related moves (`Util`, `ArmorMaterial`/`ArmorType`, `GameRules` nested imports, `EntityRenderer` arity).

After `Invoke-MinecraftEntitySubpackageRemapPass` on the existing output tree (**75 Java files** touched):

| Metric | Before | After |
|---|---:|---:|
| Reported error lines (COMPILE_REPORT) | ~300 | ~300 raw (Gradle reprints) |
| Unique `file:line` error locations | ~300 | **93** |
| `AbstractGolem` / `animal.horse` / `ArmorItem.Type` / false `AnimationTest` | many | **0** |

## Pass

`Invoke-MinecraftEntitySubpackageRemapPass` in `Convert-Forge1201-ToNeoForge262.ps1`, wired **after** NeoForge 26 API pass.

Also:

- `game-rules-rewrite` ExactPrimer rule: nested `GameRules.BooleanValue|IntegerValue|Category|Key` imports → `…gamerules.GameRules.*`
- Mechanical GeckoLib: `AnimationState` → `AnimationTest` **only** if the file imports/references `com.geckolib` or `software.bernie` (vanilla `net.minecraft.world.entity.AnimationState` must stay)

## Remap table (imports + FQNs)

### Animals

| Old | New |
|---|---|
| `…entity.animal.AbstractGolem` / `IronGolem` / `SnowGolem` | `…animal.golem.*` |
| `Cow` / `AbstractCow` / `MushroomCow` | `…animal.cow.*` |
| `Pig` | `…animal.pig.Pig` |
| `Chicken` | `…animal.chicken.Chicken` |
| `Rabbit` | `…animal.rabbit.Rabbit` |
| `Parrot` / `ShoulderRidingEntity` | `…animal.parrot.*` |
| `Sheep` | `…animal.sheep.Sheep` |
| `Cat` / `Ocelot` | `…animal.feline.*` |
| `Bee` | `…animal.bee.Bee` |
| `Fox` | `…animal.fox.Fox` |
| `Panda` | `…animal.panda.Panda` |
| `PolarBear` | `…animal.polarbear.PolarBear` |
| `Squid` / `GlowSquid` | `…animal.squid.*` |
| `Turtle` | `…animal.turtle.Turtle` |
| `Dolphin` | `…animal.dolphin.Dolphin` |
| `WaterAnimal` / `AbstractFish` / `Cod` / `Salmon` / `Pufferfish` / `TropicalFish` / `AbstractSchoolingFish` | `…animal.fish.*` |
| `…entity.animal.horse.` | `…entity.animal.equine.` |

Apply **longest FQN first** so `Zombie` does not eat `ZombieVillager` / `ZombifiedPiglin`.

### NPC / illager / undead

| Old | New |
|---|---|
| `…npc.Villager` / `AbstractVillager` / `VillagerData` / `VillagerProfession` / `VillagerType` / `VillagerDataHolder` | `…npc.villager.*` |
| `…npc.VillagerTrades` | `…item.trading.VillagerTrades` (26.2 truth; **not** under `npc.villager`) |
| `…npc.WanderingTrader` / `WanderingTraderSpawner` | `…npc.wanderingtrader.*` |
| `Evoker` / `Pillager` / `Vindicator` / `Illusioner` / `AbstractIllager` / `SpellcasterIllager` | `…monster.illager.*` |
| `Zombie` / `Husk` / `Drowned` / `ZombieVillager` / `ZombifiedPiglin` | `…monster.zombie.*` |
| `Skeleton` / `Stray` / `WitherSkeleton` / `AbstractSkeleton` / `Bogged` | `…monster.skeleton.*` |
| `Spider` / `CaveSpider` | `…monster.spider.*` |

### Util / armor / gamerules / renderer

| Old | New | Notes |
|---|---|---|
| `net.minecraft.Util` | `net.minecraft.util.Util` | **Case-sensitive** remaps only (`-creplace`). Ignore-case `-replace` corrupts `util.Mth` → `util.Util.Mth`. |
| `…item.ArmorMaterial` | `…item.equipment.ArmorMaterial` | Constructor / repair / layer API reshape is **partial** — imports move; full MCreator armor registration often still fails (`Layer`, sound Optional, etc.). |
| `…item.ArmorItem.Type` | `…item.equipment.ArmorType` | Also rewrite bare `Type.BOOTS`… when that import was present. |
| `…item.ArmorMaterial.Layer` | `…equipment.ArmorMaterial.Layer` | Layer nested type is gone in 26.2; leave for a later armor pass. |
| `…level.GameRules` (+ nested `BooleanValue`/`Category`/`Key`/`IntegerValue`) | `…level.gamerules.GameRules` (+ same nested names) | Nested types themselves were replaced by `GameRule` / `GameRuleCategory` in 26.2 — package move only here. |
| `extends EntityRenderer<T>` (exactly one type arg) | `extends EntityRenderer<T, LivingEntityRenderState>` | Adds `LivingEntityRenderState` import when missing. Further `createRenderState()` overrides still needed. |

## Follow-up pass: `Invoke-Minecraft262CompileRepairPass`

Wired after the entity-subpackage pass. Encodes gecko_kings 26.2 compile repairs:

| Area | Encoding |
|---|---|
| GameRules | `Key<BooleanValue>` + `GameRules.register` → `GameRule<Boolean>` + `GameRules.registerBoolean(..., GameRuleCategory.*)` |
| ArmorMaterial | Drop `Layer`; 8-arg `equipment.ArmorMaterial(durability, Map.of(ArmorType…), enchant, sound, tough, knock, TagKey, EquipmentAssets key)` |
| Spawn eggs | `DeferredSpawnEggItem` → `SpawnEggItem(p.spawnEgg(type.get()))` via `registerItem` |
| Fog | `FogRenderer` → `client.renderer.fog.*`; fog hooks → `FogData`/`FogEnvironment`/`Vector4f` |
| Tools | Anonymous `Tier` → `ToolMaterial` + `Properties.sword` |
| Sounds | `SOUND_EVENT.get` → `getValue` |
| Misc | `InteractionResult` import; FluidHandler capability stub; strip HierarchicalModel animator / entity-typed glow `RenderLayer` / `getArmorTexture(..., Layer)`; class-scope `createRenderState()` |

## Remaining top errors (after both passes)

Unique locs ≈ **91** (was ~93 after subpackage-only; composition changed). Cleared Layer/BooleanValue/DeferredSpawnEgg/Fog package/Tier/HierarchicalModel.

Still blocking jar:

- LivingEntityRenderState migration (`scale`/`submit` still entity-typed; acid projectile renderers)
- `MobEffect.applyEffectTick`, `Mob.customServerAiStep`, `ServerBossEvent` ctor
- Block `register(String, ::new)` needing Properties function form
- `AbstractThrownPotion` abstract; `EntityType.is(TagKey)` API; `EffectRenderingInventoryScreen`
- Glow eyes layers stripped (need RenderState-based `RenderLayer` rewrite)

## Pitfalls

1. **Never** use PowerShell `-replace` for `net.minecraft.Util` — it is case-insensitive and rewrites `net.minecraft.util.*`.
2. Do **not** blanket `AnimationState` → `AnimationTest`; that breaks vanilla entity animation fields.
3. `VillagerTrades` destination is `item.trading`, not `npc.villager`.
4. Inject `createRenderState()` at **class** scope — not inside constructors with nested `addLayer({...})`.
5. `.NET [regex]::Replace` treats `$name` in replacement strings as group refs; concatenate PowerShell vars instead.
