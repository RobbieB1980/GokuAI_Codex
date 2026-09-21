# CASE-004 — Medical System (medsystem) NeoForge 1.21.1 → 26.2

## Status

**Completed / installable / in-game verified (2026-08-30).**  
Converter path: decompile `medsystem-neoforge-2.12.1+1.21.1.jar` → NeoForge 26.2 scaffold → mechanical API + DFU repair + soft-dep exclude + **green** overlay → green `gradlew build`.  
Installable JAR: `medsystem-2.12.1+mc26.2-neoforge.jar` (~1.0 MB).  
User confirmed in-game on NeoForge **26.2.0.72** with TarkovCraft Core + Configuration.

**2.0.4 reconvert fix (2026-08-30):** Fresh Mode B after 2.0.3 still failed (~90 errors) because `lib/overlays/medsystem/1.21.1.zip` had been built from broken author-oracle DFU sources and overwrote `Invoke-DfuCodecRepairPass`. Overlay rebuilt from the proven green tree; `DELETE.txt` removes soft-dep Integration classes, Vineflower util leftovers, broken shaders, and non-compiling debug mixins; `medsystem.mixins.json` drops those mixin refs. Re-applied overlay → `gradlew build` SUCCESS → same ~1.0 MB jar. Shipped as converter **2.0.4** (GUI version + GitHub release).

**Note:** When an official 26.2 MedSystem exists (`2.13.0+26.2`), prefer that for play. This case proves the converter can lift 1.21.1 when no official 26.2 build is available.

## Paths

| Role | Path |
|---|---|
| Input jar | `C:\Users\rmbel\Downloads\medsystem-neoforge-2.12.1+1.21.1.jar` |
| 26.2 project | `C:\Users\rmbel\Downloads\medsystem-neoforge-2.12.1+1.21.1-26.2` |
| Working libs jar | `...\build\libs\medsystem-2.12.1+mc26.2-neoforge.jar` |
| Required deps | `tarkovcraft_core-neoforge-2.10.1+26.2.jar`, `configuration-neoforge-4.1.3+26.2.jar` |
| Overlay artifact | `tools/lib/overlays/medsystem/1.21.1.zip` (+ knowledge `cases/medsystem-1.21.1/artifacts/`) |

## Detection

- **modId:** `medsystem`
- **SourceVersion:** `1.21.1`
- **Loader:** `neoforge`
- **Route:** `neoforge-1.21.x`
- **Solved index:** `CASE-004-medsystem-1.21.1`

## Encoded converter pieces

1. **Mechanical (NeoForge26 API pass):** UseAnim→ItemUseAnimation; InteractionResultHolder use→InteractionResult; AddReloadListenerEvent→AddServerReloadListenersEvent; LootContextParam→ContextKey; advancements critereon→predicates/triggers; LayeredDraw→GuiLayer; Core ARGB→`net.minecraft.util.ARGB`; Gui.HeartType→Hud.HeartType.
2. **Soft-dep exclude (INT-001):** `Invoke-OptionalIntegrationExcludePass` — hard imports **and** `integration/carryon|sable|…` paths.
3. **DFU repair (DFU-001):** `Invoke-DfuCodecRepairPass` — `RecordCodecBuilder.<T>create/mapCodec` witnesses; record accessors inside balanced `.validate(...)`; mixin `(T)this`→`(T)(Object)this`; strip CheckerFramework `@NonNull`.
4. **Overlay (OVY-001):** `lib/overlays/medsystem/1.21.1.zip` must be the **green** Java tree, **not** raw author-oracle decompile. Include `DELETE.txt` + synced `medsystem.mixins.json`.
5. **Client register fix:** `MedicalSystemClient` raw `Class` + cast for `registerEntityModifier` (in green overlay).

## Failure signature (2.0.3 bad overlay)

If you see all of these after “Overlays applied: medsystem/1.21.1.zip”:

- `Kind1.group` / `Codec<Object>` on `LimbConfiguration` / `HealthContainerDefinition` / `IsDamageTypeEventCondition`
- mixin `cannot be converted to LivingEntity` / `PlayerModel`
- missing `net.minecraft.Util`, `UniformSetter`, `ConsumeEffect`, soft Integration leftovers

→ rebuild overlay from green tree (OVY-001); do not only re-run DFU.

## Agent takeaway

Hand-written NeoForge 1.21.x mods need the DFU/record/mixin repair band **in addition to** Mel-style MCreator rules. Overlays applied **after** DFU must not reintroduce Vineflower DFU breakage. Prefer official 26.2 jars when published; use this case when converting older NeoForge MedSystem.

## Related

- `LEARNINGS-2.0.x-handwritten-neoforge.md`
- `DFU-001`, `OVY-001`, `INT-001`, `PKG-002`
