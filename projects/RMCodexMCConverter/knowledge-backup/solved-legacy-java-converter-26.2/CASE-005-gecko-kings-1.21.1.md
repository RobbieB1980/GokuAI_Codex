# CASE-005 — gecko_kings_avp_mod NeoForge 1.21.1 → 26.2

## Status

**Full restore compile-green / installable jar (2026-09-02) on converter 2.10.0+; re-verified on Test1 failed output the same day.**  
Clean Mode B reconvert from decompiled → ExactPrimer + mechanical + entity-subpackage + 262-repair + MCreator 1.21.x → leftover API wave grounded in station primers / this case → `gradlew build` SUCCESS.

Installable JAR: `gecko_kings_avp_mod-24.5+mc26.2-neoforge.jar` (~5.9 MB) with **80 renderers, 43 models, 93 procedures** included (datagen only excluded).

**In-game verified 2026-09-05** on NeoForge **26.2.0.72** (load + world join + clean exit). Recipe ingredient objects cleaned the same day.

Earlier interim: compile-gate jar (~5.2 MB) with client renderer/model excludes — superseded by this full restore.

**2.10.3 durable remaps** (so Mode B does not rediscover leftovers): `register("id", FooBlock::new)`→`registerBlock` when Properties ctor; acid/projectile `submit`/`extractRenderState` in 262-repair; stronger nested ArmorMaterial static rewrite; balanced-brace `registerItemExtensions` stub (no literal `` `r`n ``); `Builder.<AcidEntity>of` for AbstractArrow factories; hardened `applyEffectTick(ServerLevel,…)` + `renderInventoryText` strip.

**Same-day Test1 repair (2026-09-02):** failed output under `Downloads\Test1\…-26.2` rebuilt green after restoring CASE-005 armor/potion/entities leftovers and encoding the remaps above. Installable jar again ~5.9MB (80/43/93).

**2026-09-03 Test1 Mode B leftover repair:** 17 errors (`HumanoidModel.crouching/riding/young`, `applyEffectTick` missing `ServerLevel`, `renderInventoryText`/`EffectRenderingInventoryScreen`). Root causes: (1) `registerItemExtensions` stub was gated behind `Registries.ARMOR_MATERIAL` rewrite so it skipped already-static armor materials; (2) MCreator 1.21.x runs after 262-repair. Fix: ungated brace-depth stub + post-MCreator 262-repair sweep. `gradlew build` → ~5.9MB jar (80/43/93).

**2026-09-03 installer regression (why green repair ≠ green Mode B):** The MobEffect remaps were encoded into `Invoke-McreatorForge1201ResiduePass` only (profile gate `mcreator-1.20.1`). NeoForge 1.21.1 jobs enable `mcreator-1.21.x` and skip that residue pass, so every fresh installer run regenerated the same 9 potion errors while hand-patched folders stayed green. **2.10.5:** move `applyEffectTick(ServerLevel,…)` + `renderInventoryText` strip into `Invoke-Minecraft262CompileRepairPass` (every route + post-MCreator sweep). Re-verified Test1 → `gecko_kings_avp_mod-24.5+mc26.2-neoforge.jar` (~5.9MB; 80/43/93).

**2026-09-04 in-game crash (NeoForge 26.2.0.72):** compile-green jar failed at Bootstrap / constructMods:

`IllegalStateException: Registry is already frozen (trying to add key ResourceKey[minecraft:game_rule / minecraft:spawnHellishXenomorphs])`

from `GeckoKingsAvpModModGameRules.<clinit>` → `GameRules.registerBoolean`. 2.10.5 turned MCreator's setup-event `GameRules.register` into a static vanilla register, which writes `BuiltInRegistries.GAME_RULE` after freeze and also drops the mod namespace. **2.10.6:** `Invoke-Minecraft262CustomGameRuleDeferredRegister` follows MCreator generator-26.1.2 (`DeferredRegister.create(Registries.GAME_RULE, MODID)` + `new GameRule<>()` + bus register + `.get()` at use sites). Test1 rebuilt and copied into the 26.2.0.72 mods folder.

**2026-09-04 second crash (after GameRules fix):** RegisterEvent `Block id not set` (`PathogenVialBlock.<init>`) and `Item id not set` (`XenomorphChitinArmorItem$Helmet`). `Invoke-BlockItemIdPass` only rewrote same-line `super(Properties.of()` / `super((new Item.Properties())` and `Type::new` (no `Outer.Inner`). Vineflower multiline supers, Door/Stairs/Flower/Liquid/Button extra args, and armor inner `new Properties()` stayed no-arg + `REGISTRY.register`. Hardened to two-pass ctor rewrite then `registerBlock`/`registerItem`. `mels_deco:empty_basket` unbound ran in the same failed RegisterEvent round and may be cascade. Entity "has no attributes" lines were rollback after the failed register.

**2026-09-04 world create/join:** title screen OK; datapack load failed with `Unbound tags … biome: [forge:is_cave]`. Source: `data/.../neoforge/biome_modifier/xenomorph_boiler_biome_modifier.json` `"biomes": "#forge:is_cave"`. 26.2 `Tags.Biomes.IS_CAVE` = `c:is_cave`. Encoded `Invoke-ForgeConventionTagRewritePass` after asset restore.

**2026-09-04 creative purple/black tiles:** textures for chitin/tools were present; log `Missing block model: minecraft:item/template_spawn_egg`. 61 spawn eggs still parented to the removed 1.20.1 template. Restore two-layer template (1.21.1 `spawn_egg.png` + overlay) under the mod namespace; namespace unprefixed `item/`/`block/` parents.

**2026-09-04 server tick:** `IllegalArgumentException: Can't find attribute minecraft:tempt_range` while ticking `gecko_kings_avp_mod:chestburster`. `TemptGoal.canUse` reads `Attributes.TEMPT_RANGE`; MCreator `Mob.createMobAttributes()` does not add it. 262-repair injects `.add(Attributes.TEMPT_RANGE, 10.0)` on every entity that constructs `TemptGoal` (12 chestburster variants).

**2026-09-05 in-game verified (NeoForge 26.2.0.72):** load + world join + clean exit with TEMPT_RANGE jar. No FATAL / GameRules freeze / unbound `#forge:is_cave` / missing spawn-egg template.

**2026-09-05 recipe cleanup:** 39 datapack recipes still used legacy `{"item":"…"}` / `{"tag":"…"}` ingredients → `Couldn't parse data file` (Ingredient.CODEC wants plain `"id"` / `"#tag"`). Encoded `Invoke-Minecraft262RecipeIngredientPass` (MCreator 26.1.x datapack templates). Test1 rewritten + `gradlew build` → refreshed mods jar (~5.9MB).

## Paths

| Role | Path |
|---|---|
| Decompiled intake | `C:\Users\rmbel\Downloads\AVP\gecko_kings_avp_mod-24.5-neoforge-1.21.1-decompiled` |
| Full 26.2 project | `C:\Users\rmbel\Downloads\AVP\gecko_kings_avp_mod-24.5-neoforge-1.21.1-26.2-full` |
| Working libs jar | `...\26.2-full\build\libs\gecko_kings_avp_mod-24.5+mc26.2-neoforge.jar` |
| Knowledge artifact | `cases/gecko-kings-1.21.1/artifacts/` |

## Detection / evidence

- **modId:** `gecko_kings_avp_mod`
- **SourceVersion:** `1.21.1` (NeoForge) — `SOURCE_PROFILE.json` + `MIGRATION_EVIDENCE.md`
- **Route:** `neoforge-1.21.x`
- **Primers:** station `NeoForge_Primers/26.2/primer_changes_1.21.1-to-26.2` (ExactPrimer rules include `entity-render-state`)
- **Signals:** MCreator HierarchicalModel client pipeline (little/no `com.geckolib` in sources despite the mod name)

## What the primers required (and what we executed)

From `1.21.2.md` Entity Render States + `PKG-or-REN-entity-subpackages-1.21.11.md`:

| Primer / CASE requirement | Executor |
|---|---|
| `EntityModel` / `setupAnim` take `EntityRenderState` | Mechanical Java + models |
| `MobRenderer` / `EntityRenderer` gain `LivingEntityRenderState` + `createRenderState()` | Mechanical + entity-subpackage + 262-repair |
| `HierarchicalModel` removed | 262-repair strips animator |
| Projectile render uses **`submit(state, PoseStack, SubmitNodeCollector, CameraRenderState)`** (not old `render(entity,…)`) | Manual CASE-005 acid renderer rewrite mirroring `ArrowRenderer` |
| Entity subpackages / ArmorType / Util / GameRules packages | `Invoke-MinecraftEntitySubpackageRemapPass` |
| ArmorMaterial record / no `Registries.ARMOR_MATERIAL` | 262-repair + static `ArmorMaterial` |
| `applyEffectTick(ServerLevel, …)` | MCreator 1.21.x + 262-repair |
| `EntityType.is(TagKey)` → `builtInRegistryHolder().is` | 262-repair (multiline-safe) |
| `AbstractThrownPotion` → `ThrownSplashPotion` / `SPLASH_POTION` | 262-repair |
| Spawn GameRules on **ServerLevel** | 262-repair |
| Custom GameRules via **DeferredRegister(Registries.GAME_RULE)** (not static `registerBoolean`) | 262-repair (`Invoke-Minecraft262CustomGameRuleDeferredRegister`) |
| MobEffects `MOVEMENT_SLOWDOWN`→`SLOWNESS`, `JUMP`→`JUMP_BOOST` | 262-repair |

## Error ladder

| Stage | Approx unique errors |
|---|---:|
| Initial / early convert | ~300 |
| After subpackage + 262-repair | ~91 |
| Clean full reconvert (no client gate) | ~84 |
| After primer/CASE leftover wave | **0** → green jar |

## Agent takeaway

1. **Read `MIGRATION_EVIDENCE.md` + station primer shards first** — ExactPrimer rule IDs and Entity Render States diffs already name the required API shape.
2. Do **not** invent a permanent client compile gate when the primer path is unfinished; use the gate only as an interim compile proof.
3. Acid/projectile renderers must follow **`submit` + `extractRenderState`**, matching vanilla `ArrowRenderer` (26.2), not the old entity-typed `render`.
4. Encode leftovers into `Invoke-Minecraft262CompileRepairPass` so the next Mode B run does not rediscover them.

## Related

- `PKG-or-REN-entity-subpackages-1.21.11.md`
- Station primers: `knowledge/NeoForge_Primers/26.2/primer_changes_1.21.1-to-26.2/`
- `dep_changes/mcreator/mcreator-1.21.x-to-26.2.md`
- Solved index: `CASE-005-gecko-kings-1.21.1`
- 262-repair knowledge (retrieval outside converter): `C:\rmblocal_llm\knowledge\262r` (category `262r` / 26.2)
