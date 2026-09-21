# Shard — misc leaf remaps (Easy Mob Farm wave)

**Proven:** Easy Mob Farm 1.21.4 → 26.2 compile-green (2026-09-05)

| ID | Detect | Target |
|---|---|---|
| `mc-262r-customdata-copytag` | `CustomData.getUnsafe()` | `copyTag()` |
| `mc-262r-compound-getstring-or` | `tag.getString("k")` assigned to `String` | `getStringOr("k", "")` (getString returns Optional) |
| `mc-262r-resourcekey-identifier` | `ResourceKey.location()` | `identifier()` |
| `mc-262r-spawnegg-gettype` | `spawnEgg.getType(RegistryAccess, stack)` | `SpawnEggItem.getType(stack)` static |
| `mc-262r-oncraftedby` | `onCraftedBy(stack, Level, Player)` | `onCraftedBy(stack, Player)` |
| `mc-262r-hurtandbreak-hand` | `hurtAndBreak(n, player, LivingEntity.getSlotForHand(hand))` | `hurtAndBreak(n, player, hand)` |
| `mc-262r-villagerdata-type` | `villagerData.getType()` / `getProfession()` | `type()` / `profession()` → `Holder`; compare `ResourceKey` via `unwrapKey()` |
| `mc-262r-cat-frog-variants` | `CatVariant.BLACK` / `FrogVariant.TEMPERATE` | `CatVariants.BLACK` / `FrogVariants.TEMPERATE` |
| `mc-262r-cubemob-package` | `monster.Slime` / `MagmaCube` | `monster.cubemob.*` |
| `mc-262r-select-item-valuecodec` | `implements SelectItemModelProperty` | `SelectItemModelProperty<String>` + `valueCodec()` |
| `mc-262r-datacomponent-builder-generic` | `DataComponentType.builder().persistent(CODEC)` | `DataComponentType.<T>builder().persistent(...)` |
| `mc-262r-screen-extract` | `renderBackground` / `super.render` on Screen | `extractBackground` / `super.extractRenderState` |
| `mc-262r-serverplayer-level` | `serverPlayer.serverLevel()` | `serverPlayer.level()` (returns ServerLevel) |
| `mc-262r-mod-version-placeholder` | `mod_version=${file.jarVersion}` | strip `${...}` placeholders when scaffolding |
| `mc-262r-advancements-stoplistening` | `getAdvancements().stopListening()` | remove (gone in 26.2) |
| `mc-262r-modlauncher-fmlloader` | `Launcher.INSTANCE.environment()…Keys.VERSION` / `MOD_DEV` | `!FMLLoader.getCurrent().isProduction()` |
| `mc-262r-item-props-ctor-dedupe` | no-arg→`Item.Properties` rewrite when Properties ctor already exists | skip rewrite; collapse FQN+short Properties duplicate ctors |

## Converter encoding

- Cubemob / frog / feline variant packages: `Invoke-MinecraftEntitySubpackageRemapPass`
- CatVariant/FrogVariant constants + FlyingMob + modlauncher: `Invoke-Minecraft262CompileRepairPass`
- Item Properties ctor dedupe: `Invoke-BlockItemIdPass`
- GameTest always-exclude: `Invoke-OptionalIntegrationExcludePass`
