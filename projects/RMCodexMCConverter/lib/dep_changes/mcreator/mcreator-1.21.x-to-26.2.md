# MCreator NeoForge 1.21.x → NeoForge 26.2

| Change ID | Kind | Summary | Executable | Upstream / case |
|---|---|---|---|---|
| `mc-121-gui-rendersystem` | removed | Strip `RenderSystem` blend/color in GUIs | `mcreator-1.21.x` | REN-004 / CASE-003 |
| `mc-121-gui-pipelines` | replaced_by | `RenderType::guiTextured` → `RenderPipelines.GUI_TEXTURED` | `mcreator-1.21.x` | REN-004 |
| `mc-121-gui-text` | renamed | `drawString` → `text()` | `mcreator-1.21.x` | REN-004 |
| `mc-121-gui-extractor` | replaced_by | `GuiGraphics` / `renderBg` → extractor APIs | `mcreator-1.21.x` | MOAdecor / Mel |
| `mc-121-client-packets` | replaced_by | `PacketDistributor.sendToServer` → `ClientPacketDistributor` (avoid double prefix) | `mcreator-1.21.x` | REN-004 |
| `mc-121-permissions` | signature_changed | CommandSourceStack `_level\w*` → `LevelBasedPermissionSet.OWNER` | `neoforge-26-api` | REN-004 |
| `mc-121-optional-nbt` | signature_changed | PersistentData `getBooleanOr` / TagValueInput | `neoforge-26-api` | REN-004 |
| `mc-121-item-lifecycle` | signature_changed | `hurtEnemy` void; `inventoryTick` slot capture | `mcreator-1.21.x` | REN-004 |
| `mc-121-fluid-overlay` | removed | drop `shouldDisplayFluidOverlay` / bad ItemHandler binds | `mcreator-1.21.x` | MOAdecor |
| `mc-121-generator-1211` | evidence | Template shape at source era | advisory | `_upstream/mcreator/plugins/generator-1.21.1/neoforge-1.21.1` |
| `mc-121-generator-261` | evidence | Nearest official generator toward 26.x | advisory | `_upstream/mcreator/plugins/generator-26.1.x/neoforge-26.1.2` |
| `mc-121-no-generator-262` | gap | No MCreator `generator-26.2` yet | converter ExactPrimer + passes | catalog |
| `mc-121-boss-uuid` | signature_changed | `ServerBossEvent` needs `UUID` first | `neoforge-26-api` / 262-repair | CASE-005 |
| `mc-121-ai-step-level` | signature_changed | `customServerAiStep(ServerLevel)` | 262-repair | CASE-005 |
| `mc-121-armor-record` | removed | No `Registries.ARMOR_MATERIAL`; static `ArmorMaterial` + `humanoidArmor`; stub `registerItemExtensions` (balanced braces) | 262-repair | CASE-005 |
| `mc-121-acid-builder-of` | signature_changed | `Builder.of(AcidEntity::new)` → `Builder.<AcidEntity>of` when ctor takes `EntityType<? extends AbstractArrow>` | 262-repair | CASE-005 |
| `mc-121-effect-tick-level` | signature_changed | `applyEffectTick(ServerLevel, LivingEntity, int)` | `mcreator-1.21.x` | CASE-005 |
| `mc-121-potion-named` | signature_changed | `new Potion(String name, MobEffectInstance...)` | 262-repair | CASE-005 |
| `mc-121-client-render-gate` | behavioral | Interim exclude only — superseded by full restore | project gate | CASE-005 |
| `mc-121-submit-projectile` | signature_changed | Projectile renderers use `submit(state,…,CameraRenderState)` not entity `render` | `262-repair` (ArrowRenderer pattern) | CASE-005 / primer 1.21.2 |
| `mc-121-registerblock-methodref` | signature_changed | `REGISTRY.register("id", FooBlock::new)` → `registerBlock` when ctor takes `Properties` | `block-item-id` | CASE-005 / REG-001 |
| `mc-121-entity-type-tag` | signature_changed | `getType().is(TagKey)` → `builtInRegistryHolder().is` (multiline) | 262-repair | CASE-005 |
| `mc-121-thrown-splash` | replaced_by | `AbstractThrownPotion` → `ThrownSplashPotion` / `SPLASH_POTION` | 262-repair | CASE-005 |
| `mc-121-gamerules-serverlevel` | signature_changed | Spawn GameRules via `ServerLevel.getGameRules()` | 262-repair | CASE-005 |
| `mc-121-gamerules-deferred` | replaced_by | Custom rules: `DeferredRegister(Registries.GAME_RULE)` + `new GameRule<>()`; never static `GameRules.registerBoolean` (frozen registry) | 262-repair | CASE-005 / MCreator 26.1.2 |

## Provenance

- Solved: CASE-003 Mel's DeCo 1.21.4, REN-004, LEARNINGS Band A, MOAdecor BATH 1.21.8, CASE-005 gecko_kings_avp_mod 1.21.1 (compile-green)
- Station upstream: `knowledge/_upstream/mcreator` @ see `_STATUS.json`
- Catalog: `MCreator-generator-delta-catalog.md`
- 262-repair retrieval tree (outside converter): `C:\gokuai\Data\262r`
