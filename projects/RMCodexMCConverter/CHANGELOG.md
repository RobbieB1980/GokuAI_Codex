## 2.10.13 — 2026-09-06

Catch-up release after GokuAI-only indexer + workspace launcher polish:

- Packaging includes latest `gokuai-workspace-overlay` (GokuAI-only knowledge rules, skills/agents).
- `Sync-GokuaiConverterWorkspace -SkillsOnly` for arbitrary/new workspaces.
- Aligns installer Fix-in-Grok with live GokuAI `Open-GokuAIWorkspace` repair preset path.
## 2.10.12 — 2026-09-05

Fix-in-Grok knowledge/MCP hardening:

- Project MCP **minecraft-knowledge** uses `C:\gokuai\runtime\mia-kit\.venv` + `DataIndex\minecraft-knowledge\knowledge.db` (not broken `runtime\.venv` mcp 2.x).
- `Open-GrokRepairSession.ps1` registers project MCP, refreshes `knowledge-context.json`, preserves tuned `.grok/rules`, and embeds MCP tool order in `GROK_REPAIR_PROMPT.md`.
- Canonical agent retrieval remains knowledge.v5 + MCP; `goku-data.db` is rebuilt legacy/benchmark FTS only.

## 2.10.11 — 2026-09-05

Destination JDK pin for installer **and agent** builds:

- `Invoke-GradleBuildWithRequiredJava` always resolves the **destination** JDK major (Java **25** for NeoForge 26.2) and sets `JAVA_HOME` — ignores ambient Java-8 `JAVA_HOME`/PATH.
- Writes `org.gradle.java.home` into the output `gradle.properties` at scaffold and again before `-Compile`, so bare `gradlew` / Fix-in-Grok repairs also use destination Java.
- `Get-ProjectRequiredJavaMajor` also maps `minecraft_version` from `gradle.properties` (26.x → 25).
- New `tools/Build-WithDestinationJava.ps1` — agents must use this (not ambient `gradlew`) for validation.
- `Write-GrokRepairPrompt` embeds the destination-Java mandate; `Open-GrokRepairSession` + compile-failure path always refresh it and pin JDK 25.
- Dependency converted-jar builds also call `Invoke-GradleBuildWithRequiredJava`.
- Agent rules: `.grok/rules/session-knowledge-context.md`, `Agents.md`, `262r/converter/destination-java.md`, `262r/do-not.md`.

## 2.10.9 — 2026-09-05

Easy Mob Farm (CASE-006) + dependency/knowledge hardening:

- **Dual-version deps:** for each detected dependency, download the detected source MC version jar (`libs-source/`) and the NeoForge **26.2** jar (`libs/`). Convert fallback uses detected source version (not hardcoded 1.20.1).
- **Import detect fix:** `Select-String -SimpleMatch` without regex Escape so `mezz.jei` → JEI is found again.
- **Soft-dep exclude:** keep `compat/jei` (etc.) when a matching jar is already in `libs/`.
- **Fix-in-Grok:** `Start-GokuAI.ps1` passes a PromptFile pointer instead of multiline bat args (FAILED OUTPUT path no longer truncated).
- **Capability stub:** multiline `ItemHandler.BLOCK` `registerBlockEntity` rewrite (no orphan `);`).
- **262r knowledge:** `converter/` + `shards/` + refreshed `catalog.json`; agent search order updated.
- **GitHub backup:** `knowledge-backup/262r` + solved CASE notes shipped in repo for PC-loss recovery.
- Strip `${file.jarVersion}` placeholders from scaffolded `mod_version`.
## 2.10.8 â€” 2026-09-05

Knowledge rewired fully onto **GokuAI** (no `C:\rmblocal_llm` dependency for repair/MCP):

- Minecraft knowledge root: `C:\gokuai\Data`
- Canonical agent index: `C:\gokuai\DataIndex\minecraft-knowledge\` + MCP **minecraft-knowledge**
- MCP: `C:\gokuai\scripts\knowledge_mcp.py` via `C:\gokuai\runtime\mia-kit\.venv` (see 2.10.12)
- Fix-in-Grok prompt primers/CASE paths now under `C:\gokuai\Data`
- Removed in-tree duplicate `knowledge.db` copy and alternate primer_changes folder under Data
## 2.10.7 â€” 2026-09-05

Fix-in-Grok failure handoff now launches **GokuAI**:

- GUI + `Open-GrokRepairSession.ps1` call `C:\gokuai\Start-GokuAI.ps1` with workspace `C:\gokuai\projects\RB-Legacy-Java-Converter`.
- Replaces the old `C:\rmblocal_llm\Start-GrokBuild.ps1` path.
- Prompt still forces MIGRATION_EVIDENCE / primer_changes / CASE files before inventing fixes; knowledge roots remain under `C:\gokuai\Data`.
## 2.10.6 â€” 2026-09-04 / 2026-09-05

CASE-005 in-game bootstrap crash on NeoForge 26.2.0.72:

- `GeckoKingsAvpModModGameRules.<clinit>` called `GameRules.registerBoolean("spawnHellishXenomorphs", â€¦)` during AutomaticEventSubscriber class load.
- `BuiltInRegistries.GAME_RULE` is already frozen â†’ `IllegalStateException: Registry is already frozen` (key landed in `minecraft:` because the name had no namespace).
- 2.10.5 compile remap was the cause: MCreator `FMLCommonSetupEvent` + `GameRules.register` became static `registerBoolean`, which compiles but crashes at constructMods.
- Fix: `Invoke-Minecraft262CustomGameRuleDeferredRegister` (from 262-repair) matches MCreator **26.1.2** â€” `DeferredRegister.create(Registries.GAME_RULE, MODID)`, `new GameRule<>()` supplier, `REGISTRY.register(modEventBus)`, use-site `.get()` on DeferredHolder.
- Re-verified: Test1 `gradlew build` â†’ `gecko_kings_avp_mod-24.5+mc26.2-neoforge.jar` (~5.9MB). Copied into the 26.2.0.72 instance mods folder.
- In-game follow-up (same day): GameRules freeze gone; next crash was `Block id not set` (`PathogenVialBlock`) and `Item id not set` (`XenomorphChitinArmorItem$Helmet`). `Invoke-BlockItemIdPass` missed multiline `super(Properties.of())`, extra super-args (Door/Stairs/Flower/Liquid/Button), armor inner `new Properties()`, and `Outer.Inner::new` method-refs. Two-pass ctor-then-`registerBlock`/`registerItem` (MCreator 26.1.2). `mels_deco:empty_basket` unbound looked like a cascade after gecko_kings failed the BLOCK RegisterEvent.
- World create/join: `Unbound tags in registry â€¦ biome: [forge:is_cave]` from `xenomorph_boiler_biome_modifier.json`. NeoForge 26.2 `Tags.Biomes.IS_CAVE` is `c:is_cave`. `Invoke-ForgeConventionTagRewritePass` after asset restore (`#forge:` â†’ `#c:`). mels_deco `minecraft:chain`/`potion` tag misses logged as non-fatal.
- Creative menu purple/black: 26.2 removed `minecraft:item/template_spawn_egg` (`Missing block model: minecraft:item/template_spawn_egg`). gecko_kings tab is ~61 spawn eggs still using that parent. `Invoke-Minecraft262ItemModelPass` restores a 1.21.1 two-layer template into the mod namespace and namespaces `item/`/`block/` parents to `minecraft:`.
- World tick crash: `Can't find attribute minecraft:tempt_range` on `ChestbursterEntity` (`TemptGoal.canUse`). `Mob.createMobAttributes()` omits `Attributes.TEMPT_RANGE` (default 10). 262-repair adds it whenever `TemptGoal` is present (12 chestburster variants).
- **2026-09-05 in-game verified:** NeoForge 26.2.0.72 load + world join + clean exit (no FATAL / GameRules / TEMPT_RANGE). Remaining noise was recipe parse errors.
- Recipe cleanup: `Invoke-Minecraft262RecipeIngredientPass` rewrites legacy `{"item":"id"}` / `{"tag":"id"}` ingredient objects to plain `"id"` / `"#id"` strings (MCreator 26.1.x datapack shape; 26.2 `Ingredient.CODEC`). Test1 39 recipes rewritten â†’ rebuild â†’ mods jar refreshed. Duplicate `medsystem-2.12.1` removed (2.13.0 kept).

## 2.10.5 â€” 2026-09-03

Installer regression root cause (why hand-repair went green, Mode B failed again):

- CASE-005 `applyEffectTick(ServerLevel,â€¦)` + `renderInventoryText` strip lived only in `Invoke-McreatorForge1201ResiduePass` (gated on profile pass `mcreator-1.20.1`).
- NeoForge **1.21.x** jobs only enable `mcreator-1.21.x`, so Mode B never applied those remaps; SESSION notes incorrectly claimed they were in `262-repair`.
- Fix: copy the MobEffect remaps into `Invoke-Minecraft262CompileRepairPass` (runs every route + post-MCreator sweep). Residue pass keeps an idempotent copy with a local `$nlFx`.
- Re-verified: Test1 `gecko_kings` â†’ 262-repair touches 9 potion units â†’ `gradlew build` expected green jar.

## 2.10.4 â€” 2026-09-03

CASE-005 Mode B leftover repair (Test1 `gecko_kings` failed output â†’ green jar):

- `262-repair`: `registerItemExtensions` stub is **ungated** from `Registries.ARMOR_MATERIAL` rewrite; brace-depth walker handles anon-class + method + if nesting (`HumanoidModel.crouching/riding/young` removed in 26.2).
- `262-repair`: strip `renderInventoryText` / `GuiGraphicsExtractor` imports only when unused in the **body** (was documented here, but the MobEffect body remaps were still only on the 1.20.1 residue pass until 2.10.5).
- Pipeline: re-run `Invoke-Minecraft262CompileRepairPass` after `mcreator-1.21.x` when that pass touches files.
- Re-verified: Test1 â†’ `gradlew build` â†’ `gecko_kings_avp_mod-24.5+mc26.2-neoforge.jar` (~5.9MB; 80/43/93).

## 2.10.3 â€” 2026-09-02

CASE-005 remaps that Mode B still missed on `gecko_kings` Test1 re-run:

- `block-item-id`: `REGISTRY.register("id", FooBlock::new)` â†’ `registerBlock` when the block ctor takes `Properties` (no-arg ctors stay on `register`).
- `262-repair`: acid/projectile `EntityRenderer.render(entity,â€¦)` â†’ `submit`/`extractRenderState` (ArrowRenderer / primer entity-render-state); projectile model `setupAnim(LivingEntityRenderState)`.
- `262-repair`: stronger nested `Registries.ARMOR_MATERIAL` â†’ static `ArmorMaterial` rewrite.
- `262-repair` hotfix (same-day Test1 repair): `registerItemExtensions` stub must use balanced braces + real newlines (single-quoted `` `$1`r`n `` left literal backticks / orphaned method bodies).
- `262-repair`: `EntityType.Builder.of(FooAcidEntity::new` â†’ `Builder.<FooAcidEntity>of` when ctor takes `EntityType<? extends AbstractArrow>`.
- `262-repair`: harden `applyEffectTick(ServerLevel,â€¦)` + strip removed `renderInventoryText` / unused `GuiGraphicsExtractor` imports.
- Re-verified: Test1 `gecko_kings_avp_mod-24.5-neoforge-1.21.1-26.2` â†’ `gradlew build` â†’ `gecko_kings_avp_mod-24.5+mc26.2-neoforge.jar` (~5.9MB; 80 renderers / 43 models / 93 procedures).

## 2.10.2 â€” 2026-09-02

GrokBuild failure handoff + primer/CASE-first session wiring.

- GUI: **Fix in Grok** button + post-failure prompt launches `C:\rmblocal_llm\Start-GrokBuild.ps1` against the station converter workspace with a primer/CASE-first repair prompt (`GROK_REPAIR_PROMPT.md` in the failed output).
- `Start-GrokBuild.ps1`: optional `-Prompt` / `-PromptFile`.
- `generate_project_knowledge_context.py`: mandatory order â€” SESSION / MIGRATION_EVIDENCE / primer_changes / CASE files **before inventing fixes**.
- Station converter project initialized with `.rb-migration` + refreshed `.grok/rules`.
# 2.10.1 â€” 2026-09-02

CASE-005 gecko_kings full-restore tools rebuild (GUI Setup + Portable).

- Ships Invoke-Minecraft262CompileRepairPass leftovers from full AVP restore: multiline `EntityType.builtInRegistryHolder().is`, `ThrownSplashPotion`, ServerLevel GameRules, MobEffects SLOWNESS/JUMP_BOOST, sword bare `F` â†’ `-0.8F`, plus prior 2.10.0 CASE-005 armor/boss/AI remaps.
- Solved index notes updated for full restore jar (~5.9MB; renderers/models/procedures).
- Knowledge: `CASE-005-gecko-kings-1.21.1.md` full-restore status.
# 2.10.0 â€” 2026-09-02

Test build: incremental migration evidence + MedSystem overlay hardening on the 2.0.3 converter baseline.

### Hotfix (same 2.10.0 AppData patch)

- Shared Java selection in `ConversionCore.ps1`: detect required major from tool JAR bytecode or project `build.gradle` (`JavaLanguageVersion.of` / `options.release`), then pick exact/closest-higher installed JDK.
- Vineflower decompile uses that path (needs 17+; ignores Java-8 `JAVA_HOME`).
- Gradle `-Compile` sets `JAVA_HOME` from the NeoForge 26.2 toolchain requirement (**Java 25**) before `gradlew build` (fixes `Gradle requires JVM 17+ ... configured to use JVM 8`).

### CASE-005 gecko_kings_avp_mod (full restore)

- Proven full jar: `gecko_kings_avp_mod-24.5+mc26.2-neoforge.jar` (~5.9MB) â€” 80 renderers, 43 models, 93 procedures (datagen exclude only). Project: `â€¦-26.2-full`.
- Grounded in station `primer_changes_1.21.1-to-26.2` Entity Render States + `MIGRATION_EVIDENCE.md` ExactPrimer rule `entity-render-state`.
- Acid projectiles: `submit(state, PoseStack, SubmitNodeCollector, CameraRenderState)` + `extractRenderState` (vanilla `ArrowRenderer` shape), not old entity-typed `render`.
- `Invoke-Minecraft262CompileRepairPass` also encodes: multiline `getType().builtInRegistryHolder().is`; `ThrownSplashPotion`/`SPLASH_POTION`; ServerLevel GameRules; MobEffects `SLOWNESS`/`JUMP_BOOST`; sword attack-speed bare `F` â†’ `-0.8F`; prior armor/boss/AI/arrow remaps.
- Interim client compile-gate jar (~5.2MB) superseded. Not in-game verified yet.

### Migration evidence packet

- Convert writes `MIGRATION_EVIDENCE.md` / `.json` after dependency detection.
- NeoForge track uses station `primer_changes_<src>-to-26.2` when present, else bundled `lib/primer_changes/` index stubs.
- Hard-dep tracks for **GeckoLib** and **MCreator** when signaled (`lib/dep_changes/`).
- ExactPrimer / GeckoLib / MCreator passes remain the executors; packet is query-filtered incremental evidence.
- Station: cloned `knowledge/_upstream/mcreator` (MCreator/MCreator) + `MCreator-generator-delta-catalog.md`.

### MedSystem overlay

- Rebuilt `lib/overlays/medsystem/1.21.1.zip` from the proven green `oldmedsystem` tree (previous zip matched broken author-oracle DFU sources and undid `Invoke-DfuCodecRepairPass`).
- Overlay `DELETE.txt` now removes soft-dep Integration classes, Vineflower util leftovers (`MedsystemCodecs`/`Weighted*`), broken client shaders, and non-compiling debug mixins.
- Overlay `medsystem.mixins.json` no longer references deleted `DebugRendererMixin` / `EntityRenderDispatcherMixin`.
- Soft-dep exclude also matches `integration/carryon|sable|jei|appleskin` paths (not only hard imports).
- Proven after overlay apply: `gradlew build` â†’ `medsystem-2.12.1+mc26.2-neoforge.jar` (~1.0MB).

## 2.0.3 â€” 2026-08-30

MedSystem 1.21.1 Ã¢â€ â€™ 26.2 converter path (CASE-004) proven in-game.

- `Invoke-DfuCodecRepairPass`: `RecordCodecBuilder.<T>create/mapCodec` type witnesses; record accessors inside balanced `.validate(...)`; mixin `(T)this` Ã¢â€ â€™ `(T)(Object)this`; strip CheckerFramework `@NonNull`.
- `Invoke-OptionalIntegrationExcludePass`: drop Carry On / Sable soft-dep sources when absent.
- NeoForge26 API: UseAnim, InteractionResultHolder use, AddServerReloadListenersEvent, ContextKey, advancements predicates/triggers, GuiLayer, ARGB, Hud.HeartType.
- Overlay `lib/overlays/medsystem/1.21.1` + `DELETE.txt` support in overlay apply.
- Proven: `medsystem-2.12.1+mc26.2-neoforge.jar` loads on NeoForge 26.2.0.72 with Core + Configuration.
## 2.0.2 Ã¢â‚¬â€ 2026-08-30

Hotfix after 2.0.1: Mel's DeCo fresh reconvert still failed compile (~258 errors) after GUI wave.

- `loadWithComponents(CompoundTag, RegistryAccess)` Ã¢â€ â€™ `TagValueInput.create(ProblemReporter.DISCARDING, ...)` + imports.
- CommandSourceStack permission rewrite matches `_level\w*` (`_levelx` / `_levelxxxxxx`), not only exact `_level`.
- PersistentData Optional accessors: `getBooleanOr` / `getStringOr` / `getIntOr` / `getDoubleOr`.
- inventoryTick: capture 4th slot arg (fixes literal `$4`); armor worn check via `List.of(getItemBySlot HEAD/CHEST/LEGS/FEET)`.
- void hurtEnemy strips leftover `return true/false`.
- ItemOwner for RangeSelect/LegacyOverride; ConditionalItemModelProperty uses `asLivingEntity()`.
- PacketDistributor: keep `sendToPlayer` import; avoid `ClientClientPacketDistributor` double-prefix.
- Proven: Mel `gradlew build` SUCCESS Ã¢â€ â€™ `mels_deco-1.2+mc26.2-neoforge.jar` (~13.1MB).
- In-game verified 2026-08-30: Mel + NextGen load on NeoForge 26.2.0.72.
## 2.0.1 Ã¢â‚¬â€ 2026-08-30

Hotfix after 2.0.0: Mel's DeCo fresh reconvert still failed compile after ExactPrimer (479 files).

- Encoded Mel/MCreator 1.21.4Ã¢â€ â€™26.2 GUI/API rules into `Invoke-Mcreator1218ToNeoForge262Pass`:
  strip RenderSystem blend/color, `RenderType::guiTextured`Ã¢â€ â€™`RenderPipelines.GUI_TEXTURED`, `drawString`Ã¢â€ â€™`text()`, `ClientPacketDistributor.sendToServer`, yield/break cleanup, emissiveRendering 1-arg, GameProfile.id(), Level weather via instanceof, copyTag Optional NBT, item tooltip/hurtEnemy/inventoryTick.
- ExactPrimer: emissiveRendering 3-argÃ¢â€ â€™1-arg after hasPostProcess rename.
- Proven: Mel `gradlew build` SUCCESS after applying encoded rules.
- In-game verified 2026-08-30: Mel + NextGen load on NeoForge 26.2.0.72.
## 2.0.0 Ã¢â‚¬â€ 2026-08-30

Major release: Mel's DeCo 1.21.4 reconvert path made reliable end-to-end.

- Restored full `Invoke-ExactPrimerMigrationRules` (ArmorItem/SwordItem/SingleQuadParticle/TriState/ValueIO/GameRules/etc.).
- PrimerChangeIndex Mel rule IDs restored (13 rules after 1.21.4).
- JPMS-001: `Legacy262Compat` under `rb.legacy.converter.compat.<modId>`.
- `Blocks.CHAIN` / `Items.CHAIN` word-boundary only (no CHAINSAW / CHAIN_LINK mangling).
- GUI 26.2: strip RenderSystem blend/color; `RenderPipelines.GUI_TEXTURED`; `text()`; ClientPacketDistributor.
- Proven Mel + NextGen load together on NeoForge 26.2.0.72.
## 1.5.5-hotfix3 Ã¢â‚¬â€ 2026-08-29

- **JPMS split-package fix:** `Legacy262Compat` is now emitted under `rb.legacy.converter.compat.<modId>` (via `Get-Legacy262CompatPackage` + `Convert-NeoForge262ApiMoves -ModId`). Shared `rb.legacy.converter.compat` caused `ResolutionException` when Mel's DeCo and NextGen Furniture loaded together (both exported the package to JEI).
- `Invoke-MechanicalJavaRewrites` takes `-ModId`, rewrites legacy shared FQCNs, deletes the old shared compat class, and writes the helper only when call sites need it.
- Proven: Mel jar ships with no `rb/` entries (unused compat removed); NextGen rebuilt with `...compat.nextgen_furniture.Legacy262Compat`.

## 1.5.5-hotfix1 Ã¢â‚¬â€ 2026-08-29

- Fixed solved overlays looking under `overlays/` instead of `lib/overlays/` (Nextgen overlay never applied).
- Apply semantic overlays **after** all rewrite passes so `BlockEntityType` helpers are not mangled into `EntityType.Builder`.
## 1.5.5 Ã¢â‚¬â€ 2026-08-29

Full product refresh for NeoForge **26.2.0.72**.

- GUI default NeoForge version set to `26.2.0.72` (was `26.2.0.32-beta`).
- Converter default `-NeoVersion` `26.2.0.72`; Gradle wrapper prefers station MDK `knowledge/Neoforge26.2generatortemplate`.
- Encoded completed conversions via `lib/SolvedConversionIndex.json` (auto match + overlays).
- Registry `Block id not set` SupplierÃ¢â€ â€™Function fix; installer embeds payload only.
- Exact primer rules + Nextgen/Knocker overlays; Fusion official dep-cache.
## 1.5.5-mdk Ã¢â‚¬â€ 2026-08-29

- Prefer station MDK `C:\gokuai\Data\Neoforge26.2generatortemplate` for Gradle wrapper bootstrap.
- Default `-NeoVersion` bumped to `26.2.0.72` to match that template (ModDev remains `2.0.144`).
## 1.5.4-solutions Ã¢â‚¬â€ 2026-08-29

- Encoded completed conversions into `lib/SolvedConversionIndex.json` (CASE-001/CASE-002 + source-band defaults).
- Converter auto-matches modId + detected source version, merges forced passes/transforms into `SOURCE_PROFILE.json`, and applies semantic overlays (Nextgen 1.21.1, Knocker 1.21.8).
- Hospital/1.12 inputs are guarded to the dedicated 112 pipeline.
## 1.5.3-installer Ã¢â‚¬â€ 2026-08-29

- Setup EXE now installs **only** its embedded `portable-payload.zip`. Sibling portable ZIPs beside the installer are ignored so an older zip cannot override a newer Setup.
## 1.5.3-unified Ã¢â‚¬â€ 2026-08-29

- Ported ChatGPT **v1.5.3** registry fix: custom `Supplier`-based `registerBlock` helpers become `Function<Properties, T>` + `BLOCKS.registerBlock` / `ITEMS.registerItem` so NeoForge 26.2 injects registry ids (fixes runtime `Block id not set`).
- `Convert-CustomBlockRegistrationText` is idempotent and wired into `Invoke-BlockItemIdPass`.

## 1.5.1-unified Ã¢â‚¬â€ 2026-08-29

- Unified product tree at `MC-Java-1.20.1-to-26.2-Converter`: ChatGPT v1.5.1 conversion engine + LegacyJavaConverter GUI/packaging.
- Core loop: **detect source version** Ã¢â€ â€™ select cumulative primer transitions/rules Ã¢â€ â€™ convert to NeoForge 26.2.
- Restored `Invoke-SubmitCustomGeometryPass` from the LegacyJavaConverter geometry work.
- Re-verified NextGen Furniture **1.21.1** decompile through the unified converter: full `gradlew build` and installable `nextgen_furniture-0.0.9-beta+mc26.2-neoforge.jar`.

# Changelog

## 1.5.3 Ã¢â‚¬â€ 2026-08-29

- Fixed the NeoForge 26.2 runtime crash `Block id not set` for custom `Supplier`-based block registration helpers.
- Custom block and block-item factories now receive registry-keyed properties; added idempotent regression coverage.

## 1.5.2 Ã¢â‚¬â€ 2026-08-29

- Fixed the self-contained installer preferring an older portable ZIP beside the setup EXE over its embedded payload.
- Setup now verifies the installed application version and exact-primer migration stage before reporting success.

## 1.5.1 Ã¢â‚¬â€ 2026-08-29

- Primer transitions now carry executable rule IDs, so the detected source version selects only the cumulative migration path required to reach 26.2.
- Added 1.21.1 render-state, standalone-model, block-entity value I/O, entity registration/damage, direction-property and legacy-datagen migrations.
- Added a verified semantic overlay for NextGen Furniture 1.21.1.
- Proved the untouched 1.21.1 decompile through the normal converter pipeline: full `gradlew build` and an installable `nextgen_furniture-0.0.9-beta+mc26.2-neoforge.jar`.

## 1.5.0 Ã¢â‚¬â€ 2026-08-29

Complete staged conversion and verification release.

### Detection and reference index
- Evidence-based Forge/NeoForge source detection from 1.20.1 through 26.2.
- Route-specific migration passes and `SOURCE_PROFILE.json`.
- Ordered `PrimerChangeIndex.json` and generated source-specific `PRIMER_CHANGE_INDEX.md`.

### Build and reports
- `-Compile` now runs the complete Gradle build and only reports success when `build/libs` contains an installable JAR.
- Structured compile reports, dependency report, migration report and preserved decompile report.
- Version-prefixed installable JAR handling; the original input JAR is never copied or renamed as a result.

### NeoForge 26.2 migrations
- Package moves for block-state models, variant mutators and camera render state.
- Entity `level()` versus block-entity `getLevel()` detection.
- Removed `ItemBlockRenderTypes` calls migrated to model `render_type` metadata.
- 26.2 block-model submission compatibility, packed-light lookup and standalone-model event registration.
- Stream-based block-state property copying and registry-key item tags.
- Fixed idempotency defects in client-side and color-collection rewrites.

### Dependencies and verification
- Dependency JSON compatibility and optional `MavenHint` handling.
- Official Fusion 26.2 dependency resolution.
- Verified NextGen Furniture 1.21.11 conversion with `gradlew build` and an installable NeoForge 26.2 JAR.

## 1.4.0 Ã¢â‚¬â€ 2026-08-23

Final 26.2 converter from the Knocker + The One Who Watches (TOWW) campaign.

### Jar extract
- Copy **every non-class file** from the original jar (textures, geo, animations, sounds, data, logo, mixins).
- Decompile report lists PNG/ogg/geo/animation/nbt counts and writes `original-jar.txt`.
- 26.2 convert restores assets from the source tree, sibling jar, or `-OriginalJarPath` if the decompile was Java-only.

### Mappings
- Official SRG map from workstation `Minecraft_Mappings/1.20.1` flat TSV (64,225 unique, 0 conflicts) Ã¢â€ â€™ `lib/Srg1201Official.json`.
- `Srg1201Common.json` only holds SRGs missing from that flat map (guessed overlays were renaming `playLocalSound` Ã¢â€ â€™ `setBlock`).

### NeoForge 26.2 load
- `DeferredRegister.Blocks.registerBlock` / `Items.registerItem` + `Properties` constructors (`Block/Item id not set`).
- `ForgeSpawnEggItem(entity,Ã¢â‚¬Â¦)` Ã¢â€ â€™ `properties.spawnEgg(entity.get())`.
- `queueServerWork` only on the server thread (C2ME `playLocalSound` crash).
- `Animal.createAnimalAttributes()` so `TemptGoal` has `minecraft:tempt_range`.
- Skip MCreator `OnInitialEntitySpawn` discard for `SPAWN_ITEM_USE` / `COMMAND` / `DISPENSER` / `MOB_SUMMONED`.
- Do not double-register `EntityAttributeCreationEvent`.

### GeckoLib 5
- Bare geo IDs (`toww_geckolib` Ã¢â€ â€™ `assets/<mod>/geckolib/models|animations/`).
- Real texture PNG (never `unknown.png`); `AnimationController<>` not array wrap.
- Procedure controller `STOP` when clip empty; do not flatten every form to pose1.
- TOWW live stack can use completed-port `TowwGeoModel` / `TowwGeoRenderer` / `AbstractTOWWMonster`.
- Do not store MCreator `WorldVariables` under the same SavedData id as `TowwWorldData` (`worldvars`).

### Proven
- **The Knocker** Ã¢â‚¬â€ 26.2 jar, in-game spawn.
- **The One Who Watches** Ã¢â‚¬â€ 26.2 jar loads; GeckoLib geo/anim/textures packed; spawn-egg / summon; world-data crash fixed.

## 1.2.6 Ã¢â‚¬â€ 2026-08-01

### Networking rewrite actually applies (MOAdecor BATH retest)
- **Critical fix:** v1.2.5 `MESSAGES.forEach Ã¢â€ â€™ playBidirectional` rewrite regex never matched
  real MCreator output (`playBidirectional(...));` vs broken `...;);` pattern).
- Now matches the single-line forEach lambda, injects typed `registerOne`, and when
  `network/MenuStateUpdateMessage.java` exists:
  - registers `MenuStateUpdateMessage` directly on `RegisterPayloadHandlersEvent` (4-arg)
  - strips late `@EventBusSubscriber` / `FMLCommonSetupEvent` registration
- Proven: reconverted **MOAdecor BATH** builds a loadable jar; problems report is deprecation
  warnings only (0 ERROR).

### Packaging
- GUI / Setup / portable package **1.2.6**

## 1.2.5 Ã¢â‚¬â€ 2026-08-01

### Networking forEach type-inference fix (MOAdecor GARDEN)
- **Fix:** MCreator main class pattern  
  `MESSAGES.forEach((id, msg) -> registrar.playBidirectional(...))`  
  fails to compile under Java generics wildcards  
  (`no suitable method found for playBidirectional` / CAP# constraints).
- Converter rewrites that form to a typed `registerOne` helper loop.
- Prefer registering `MenuStateUpdateMessage` on `RegisterPayloadHandlersEvent`  
  with 4-arg handlers (not `FMLCommonSetupEvent`).

Proven: **MOAdecor GARDEN 1.21.8.A** Ã¢â€ â€™ `gradlew build`.

### Packaging
- GUI / Setup / portable package **1.2.5**

## 1.2.4 Ã¢â‚¬â€ 2026-08-01

### Converter rewrite safety (MOAdecor ELECTRONICS)
- **Fix:** naive `playBidirectional` 3Ã¢â€ â€™4-arg expansion could mangle
  `networkMessage.handler()` into invalid Java  
  `handler(, handler(), handler())` (compile failure).
- Now only rewrites the exact MCreator form  
  `playBidirectional(id, msg.reader(), msg.handler())`  
  and can repair the previously corrupted form.
- **Fix:** `registerItem` rewrite no longer treats nested  
  `new BlockItem(..., prop)` as the third argument; repairs  
  `BlockItem(..., () -> prop)` and wraps only the final  
  `properties` variable as `() -> properties`.

Proven: **MOAdecor ELECTRONICS 1.21.8.A** Ã¢â€ â€™ `gradlew build` after re-apply.

### Packaging
- GUI / Setup / portable package **1.2.4**

## 1.2.3 Ã¢â‚¬â€ 2026-08-01

### MCreator / NeoForge 1.21.x Ã¢â€ â€™ 26.2 pass (MOAdecor BATH)
New rewrite pass for decompiled **1.21.8 NeoForge / MCreator** jars (in addition to Forge 1.20.1). Not a separate converter product Ã¢â‚¬â€ same Legacy pipeline + extra pass:
- Remove `shouldDisplayFluidOverlay` + old `BlockAndTintGetter` import (method gone from Block)
- `.noCollission()` Ã¢â€ â€™ `.noCollision()`
- `GuiGraphics` Ã¢â€ â€™ `GuiGraphicsExtractor`; `renderBg` Ã¢â€ â€™ `extractBackground`; tooltip/label extract renames
- Final `imageWidth`/`imageHeight` Ã¢â€ â€™ `super(menu, inv, title, w, h)` (including delayed field assigns)
- `keyPressed(int,int,int)` Ã¢â€ â€™ `keyPressed(KeyEvent)` (ESC close pattern)
- `.isClientSide` field Ã¢â€ â€™ `.isClientSide()`
- `net.minecraft.util.Tuple` delayed work queue Ã¢â€ â€™ `Object[]` holders
- Stub MCreator `ItemHandler.ITEM` / `ItemHandler.ENTITY` capability binds (transfer API is manual)
- `Minecraft.getInstance().screen` Ã¢â€ â€™ `gui.screen()`
- `registerItem(name, fn, Properties)` Ã¢â€ â€™ supplier form `() -> properties`
- Payload `StreamCodec<? extends FriendlyByteBuf` Ã¢â€ â€™ `? super RegistryFriendlyByteBuf`
- **Critical networking:** use 4-arg `playBidirectional(type, codec, handler, handler)` Ã¢â‚¬â€ 3-arg leaves client handler null and crashes with `missing client-side handlers`

Proven: **MOAdecor BATH 1.21.8.A** Ã¢â€ â€™ compile, `gradlew build`, and **client load on NeoForge 26.2.0.32-beta**.

### Packaging
- GUI / Setup / portable package **1.2.3**

## 1.2.2 Ã¢â‚¬â€ 2026-08-01

### 26.2 API rewrite expansions (BuildPaste / decompile lessons)
- `EntityType.VANILLA_FIELD` Ã¢â€ â€™ `EntityTypes.VANILLA_FIELD` (+ import)
- Full **ColorCollection** grid for `Items`/`Blocks` (`WHITE_WOOL` Ã¢â€ â€™ `WOOL.white()`, glazed terracotta, beds, carpets, Ã¢â‚¬Â¦)
- `getMainCamera()` Ã¢â€ â€™ `mainCamera()`
- `Minecraft.getInstance().renderBuffers()` Ã¢â€ â€™ `gameRenderer.renderBuffers()`
- Note: `MultiBufferSource` / `.bufferSource()` world drawing still needs manual `SubmitCustomGeometryEvent` + `submitShapeOutline` (naive renames are not enough)

### Packaging
- Bump GUI / portable package when releasing **1.2.2**

## 1.2.1 Ã¢â‚¬â€ 2026-07-25

### Critical fix (The Knocker world-join disconnect)
- **ModConfigSpec define-before-build pass:** decompiled MCreator configs that call `BUILDER.build()` before `.define(...)` caused  
  `Cannot get config value before spec is built` on player spawn Ã¢â€ â€™ **Connection lost / Disconnected**.
- Converter now reorders SPEC construction after config value definitions.

### Packaging
- GUI + Setup version **1.2.1**
- Rebuild installer / portable package

## 1.2.0 Ã¢â‚¬â€ 2026-07-25

Proven on **Friend** (runtime) and **The Knocker** (NeoForge 1.21.8 jar Ã¢â€ â€™ 26.2 compile/build).

### Critical fixes
- **Strip leftover `src/main/resources/META-INF/neoforge.mods.toml`** (and `mods.toml` / `MANIFEST.MF`) so generated templates control Minecraft/NeoForge `versionRange`.
  - Fixes loader rejection still asking for old versions such as **1.21.8**.
- Clearer docs: conversion success Ã¢â€°Â  loadable mod; only install `gradlew build` output jars; never rename the input jar as 26.2.

### API rewrite expansions (26.2)
- `displayClientMessage` Ã¢â€ â€™ `sendSystemMessage`
- `getLevelData().getSpawnPos()` Ã¢â€ â€™ `getRespawnData().pos()`
- `getRespawnConfig().pos()/dimension()` Ã¢â€ â€™ `respawnData()...`
- Broader `entity.getServer()` Ã¢â€ â€™ `level().getServer()` receivers
- `CommandSourceStack` permission int Ã¢â€ â€™ `LevelBasedPermissionSet`

## 1.1.x and earlier
See git history for initial GUI, jar pipeline, and Forge 1.20.1 scaffold support.



