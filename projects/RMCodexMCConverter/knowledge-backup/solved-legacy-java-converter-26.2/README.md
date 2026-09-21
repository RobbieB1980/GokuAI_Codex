# Solved problems — Legacy Java Converter → NeoForge 26.2

Indexed fixes agents should search before inventing new rewrites.  
**Start here for 2.0.x handwritten + MCreator bands:** [LEARNINGS-2.0.x-handwritten-neoforge.md](LEARNINGS-2.0.x-handwritten-neoforge.md)

**26.2 compile/runtime remaps (outside this converter workspace):** `C:\rmblocal_llm\knowledge\262r` (MCP category `262r`, version `26.2`). Start at `262r/INDEX.md`.

Converter tools: `C:\rmblocal_llm\projects\RB-Legacy-Java-Converter\tools`  
Encoded runtime index: `tools/lib/SolvedConversionIndex.json` (auto-applied by the converter)  
Engine helpers: `tools/lib/ConversionCore.ps1`, `tools/lib/PrimerChangeIndex.json`, `tools/lib/overlays/`  
Public releases: https://github.com/RobbieB1980/LegacyJavaConverter/releases

| ID | Symptom | Source cue | Fix location |
|---|---|---|---|
| [LEARNINGS](LEARNINGS-2.0.x-handwritten-neoforge.md) | **2.0.x decision tree** | Mel vs MedSystem vs overlay/version bugs | Index of CASE/DFU/OVY/INT/PKG |
| [CASE-001](CASE-001-nextgen-furniture-1.21.1-success.md) | **Completed reference conversion** | `nextgen_furniture` NeoForge 1.21.1 | Full build archive + reports under `cases/nextgen-furniture-1.21.1/` |
| [CASE-002](CASE-002-grokbuild-completed-26.2-index.md) | **GrokBuild completed 26.2 set** | Friend/TOWW/Knocker/MOAdecor/Hospital/… | Canonical completed 26.2 trees |
| [CASE-003](CASE-003-mels-deco-1.21.4-success.md) | **Completed 1.21.4 MCreator reference (in-game OK)** | `mels_deco` NeoForge 1.21.4 | ExactPrimer + REN-004; converter **2.0.2** |
| [CASE-004](CASE-004-medsystem-1.21.1.md) | **Hand-written 1.21.1 MedSystem (in-game OK)** | `medsystem` NeoForge 1.21.1 | DFU + soft-dep + **green** overlay; converter **2.0.4** |
| [CASE-005](CASE-005-gecko-kings-1.21.1.md) | **MCreator 1.21.1 AVP full restore jar** | `gecko_kings_avp_mod` | primers + entity-render-state submit; converter **2.10.0** |
| [DFU-001](DFU-001-recordcodecbuilder-validate-mixin.md) | `Kind1.group` / `Codec<Object>` / mixin cast | Vineflower DFU records | `Invoke-DfuCodecRepairPass` |
| [OVY-001](OVY-001-overlay-must-be-green-not-oracle.md) | Overlay applied but DFU errors return | Overlay from broken oracle | Rebuild overlay from green `src/` + `DELETE.txt` |
| [INT-001](INT-001-soft-dep-integration-exclude.md) | Soft-dep Integration still compiles | Carry On / Sable / JEI folders | Path + import exclude pass |
| [REN-004](REN-004-mels-deco-1.21.4-mechanical-rules.md) | Armor/particle/GUI/CHAINSAW/etc. on 1.21.4 | Mel's DeCo shape | ExactPrimer + ConversionCore mechanical rules |
| [REG-001](REG-001-block-id-not-set-supplier-registerBlock.md) | Runtime `Block id not set` | Custom `registerBlock(String, Supplier<T>)` | ConversionCore + BlockItemId pass |
| [DEP-001](DEP-001-fusion-supermartijn-official.md) | Wrong Fusion / recursive convert | toml `fusion` | Official Fusion dep-cache |
| [REN-001](REN-001-nextgen-furniture-1.21.1-overlay.md) | BER/standalone won't mechanical-port | `nextgen_furniture` 1.21.1 | `lib/overlays/nextgen-furniture/1.21.1/**` |
| [REN-002](REN-002-client-package-moves-26.2.md) | Missing `BlockStateModel` / render-state | Old client packages | `Convert-NeoForge262ApiMoves` |
| [REN-003](REN-003-itemblockrendertypes-to-model-render-type.md) | `ItemBlockRenderTypes` missing | `setRenderLayer(..., CUTOUT)` | Model `render_type` JSON |
| [DET-001](DET-001-source-profile-and-primer-rules.md) | Wrong passes / too much SRG on 1.21.x | Missing detection | `Get-SourceProfile` + primer rules |
| [DET-002](DET-002-primer-strictly-after-source.md) | Primer equal/below source applied | Unknown or equal destination | Strict `to > source` chain |
| [JPMS-001](JPMS-001-legacy262compat-mod-scoped-package.md) | Split package `rb.legacy.converter.compat` | Two converted jars + JEI | Mod-scoped `Legacy262Compat` |
| [PKG-001](PKG-001-installer-embedded-payload-only.md) | Old portable zip overrides new Setup | Sibling zip beside Setup | Embedded `portable-payload.zip` only |
| [PKG-002](PKG-002-release-version-bump-checklist.md) | GUI still shows old version (e.g. 1.5.5) | Tools updated, EXE not rebuilt | csproj + titles + Build-Release |

## Adding a new solved case

1. Reproduce on converter output (not hand-patched tree alone).
2. Fix in converter rule/overlay/catalog when possible.
3. Add `SOL-XXX-short-name.md` (or CASE/DFU/OVY/INT/PKG/REN) here with symptom, detection, fix path, verification.
4. Link it in this table and in `catalog.json`.
5. If it is a completed mod conversion, also encode `SolvedConversionIndex.json` + overlay so Mode B auto-applies.

## CASE-003 Mel's DeCo 1.21.4

See `CASE-003-mels-deco-1.21.4-success.md` and `cases/mels-deco-1.21.4/`.  
**Build + in-game verified 2026-08-30** on converter **2.0.2**.

## CASE-004 MedSystem 1.21.1

See `CASE-004-medsystem-1.21.1.md` and `cases/medsystem-1.21.1/`.  
**Build + in-game verified 2026-08-30**; Mode B green reconvert fixed in converter **2.0.4** (OVY-001).

## CASE-005 gecko_kings_avp_mod 1.21.1

See `CASE-005-gecko-kings-1.21.1.md` and `cases/gecko-kings-1.21.1/`.  
**Full restore build SUCCESS 2026-09-02** on converter **2.10.0** (`…-26.2-full\build\libs\gecko_kings_avp_mod-24.5+mc26.2-neoforge.jar` ~5.9MB) with renderers/models/procedures. **Not in-game verified** yet.
