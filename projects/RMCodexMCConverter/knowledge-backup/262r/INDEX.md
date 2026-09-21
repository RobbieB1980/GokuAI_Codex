# 262r â€” NeoForge 26.2 compile/runtime repair knowledge

Indexed remaps for **1.21.x (and Forge 1.20.1 residue) â†’ NeoForge 26.2**.  
This tree is **retrieval knowledge**, not the converter. Agents outside `RB-Legacy-Java-Converter` should search category **`262r`**, version **`26.2`**, or `search_solved_projects` for these IDs.

**Executable source** (do not copy into migration workspaces):  
`C:\gokuai\projects\RB-Legacy-Java-Converter\tools\Convert-Forge1201-ToNeoForge262.ps1`  
`C:\gokuai\projects\RB-Legacy-Java-Converter\tools\lib\ModDependencyPipeline.ps1`

| Pass | Function | When |
|---|---|---|
| **262-repair** | `Invoke-Minecraft262CompileRepairPass` | Every convert route, then again after `mcreator-1.21.x` if that pass touched files |
| GameRules | `Invoke-Minecraft262CustomGameRuleDeferredRegister` | Called from 262-repair |
| Block/Item id | `Invoke-BlockItemIdPass` | After registry template |
| Convention tags | `Invoke-ForgeConventionTagRewritePass` | After asset restore |
| Item models | `Invoke-Minecraft262ItemModelPass` | After client-item stubs |
| Dual deps | `Resolve-AndAcquireDependencies` | Before Gradle scaffold |

Proven on **CASE-005** `gecko_kings_avp_mod` and **Easy Mob Farm** NeoForge 1.21.4 â†’ 26.2 (compile-green 2026-09-05). Compile-green is not play-green â€” encode leftovers here so Mode B does not rediscover them.

## Agent search order (mandatory)

1. Failed output packet: `GROK_REPAIR_PROMPT.md` â†’ `MIGRATION_EVIDENCE` / `SOURCE_PROFILE` / `compile-errors`
2. **This tree (`262r`)** â€” `converter/` then matching `shards/` then `remaps.md` / `crashes.md`
3. Solved cases: `Solved_Problems/legacy-java-converter-26.2`
4. Compact `primer_changes` (one shard at a time)
5. Exact NeoForge/Minecraft **26.2** physical source (confirm API)
6. Invent only if missing â€” then write back here **and** into the converter PS1

Do **not** start with a broad walk of all of `C:\gokuai\Data`.

## Read order

1. [pipeline.md](pipeline.md) â€” when 262-repair runs (and why it must re-run after MCreator).
2. [converter/](converter/) â€” dual-deps, import-detect, soft-dep exclude, Fix-in-Grok, capability stub, destination-java.
3. [shards/](shards/) â€” open **one** family matching the current compiler/runtime error.
4. [remaps.md](remaps.md) â€” compile remaps ledger (target shape + detection).
5. [crashes.md](crashes.md) â€” in-game crash ladder after a green jar.
6. [do-not.md](do-not.md) â€” anti-patterns that regenerated the same errors.
7. Confirm any concrete API against exact NeoForge **26.2** physical source.

## Converter notes (`converter/`)

| File | Topic |
|---|---|
| [dual-deps.md](converter/dual-deps.md) | Source-version + 26.2 Modrinth pull (`libs-source/` + `libs/`) |
| [import-detect.md](converter/import-detect.md) | `mezz.jei` scan; never Escape+SimpleMatch |
| [soft-dep-exclude.md](converter/soft-dep-exclude.md) | Exclude integrations only when no `libs/*` jar |
| [fix-in-grok.md](converter/fix-in-grok.md) | PromptFile pointer; no multiline bat prompt |
| [capability-stub.md](converter/capability-stub.md) | Multiline `ItemHandler.BLOCK` stub; no orphan `);` |

## Shards (`shards/`)

| File | Topic |
|---|---|
| [value-io.md](shards/value-io.md) | ValueInput/Output, TagValue*, UUIDUtil |
| [map-entry-accessors.md](shards/map-entry-accessors.md) | `entry.property()` â†’ `getKey()` |
| [entity-type-lookup.md](shards/entity-type-lookup.md) | `EntityType.byString` â†’ BuiltInRegistries |
| [flying-mob-removed.md](shards/flying-mob-removed.md) | FlyingMob/FlyingAnimal gone |
| [block-entity-render-state.md](shards/block-entity-render-state.md) | BER `<T,S>` + submit |
| [tooltip-consumer.md](shards/tooltip-consumer.md) | Consumer\<Component\> tooltips |
| [misc-26.2-leaf.md](shards/misc-26.2-leaf.md) | Easy Mob Farm leftover wave |
| [feline-minecart-packages.md](shards/feline-minecart-packages.md) | FelineModel 26.1 split; minecart/boat packages; mixin slash + this instanceof |
| [itemstack-components-bound.md](shards/itemstack-components-bound.md) | ItemStack before components bound |

## Crash ladder (CASE-005, 2026-09-04)

| Stage | Symptom | Fix ID |
|---|---|---|
| constructMods | `Registry is already frozen` `minecraft:game_rule / â€¦` | `mc-262r-gamerules-deferred` |
| RegisterEvent | `Block id not set` / `Item id not set` | `mc-262r-block-item-id` |
| World create | `Unbound tags â€¦ biome: [forge:is_cave]` | `mc-262r-convention-tags` |
| Creative tab | Purple/black tiles; missing `template_spawn_egg` | `mc-262r-template-spawn-egg` |
| Server tick | `Can't find attribute minecraft:tempt_range` | `mc-262r-tempt-range` |
| Client setup / clinit | `Components not bound yet` / ItemStack | `mc-262r-itemstack-components-bound` |

## Search hints

- MCP: `search_knowledge(query, category="262r", version="26.2")`
- MCP: `search_solved_projects("TemptGoal TEMPT_RANGE")` / `"GameRules.registerBoolean"` / `"ValueInput"` / `"dual-deps"`
- Related solved case: `Solved_Problems/legacy-java-converter-26.2/CASE-005-gecko-kings-1.21.1.md`
- Easy Mob Farm output (2026-09-05): `C:\Projects\Easy Mod Farm\easy_mob_farm-neoforge-1.21.4-10.3.0-26.2`

