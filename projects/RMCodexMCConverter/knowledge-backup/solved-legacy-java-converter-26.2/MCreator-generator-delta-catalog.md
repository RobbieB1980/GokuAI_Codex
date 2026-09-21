# MCreator generator delta catalog (→ NeoForge 26.2)

Compact station evidence for MCreator-shaped NeoForge conversions. Prefer generator plugins over full IDE sources. Executable rewrites live in converter ExactPrimer + `mcreator-*` / `neoforge-26-api` passes — this file is the inventory + gap map those ledgers cite.

## 1. Provenance

| Field | Value |
|---|---|
| Repo | https://github.com/MCreator/MCreator.git |
| Branch | `master` |
| Commit | `1140e7457` (`1140e745774d39cf0d9e1fa66cf39e036855399d`) |
| Clone | `C:\rmblocal_llm\knowledge\_upstream\mcreator` |
| Status sidecar | `_upstream/mcreator/_STATUS.json` |

Snapshot note (STATUS): cloned 2026-09-02; “Prefer `plugins/generator-*` over full IDE sources for converter ledgers.”

## 2. Generator inventory (this master)

| Plugin id | Role | NeoForge / target path |
|---|---|---|
| `generator-1.21.1` | Java JE LTS-era generator | `plugins/generator-1.21.1/neoforge-1.21.1` (`buildfileversion: 21.1.232`, status `lts`) |
| `generator-26.1.x` | Java JE current master generator | `plugins/generator-26.1.x/neoforge-26.1.2` (`buildfileversion: 26.1.2.95`, status `stable`) |
| `generator-addon-26.1x` | Bedrock addon only | `plugins/generator-addon-26.1x/addon-26.1x` (not a NeoForge Java path) |
| `mcreator-link` | Optional Link API stubs | `neoforge-1.21.1/` and `neoforge-26.1.2/` under `plugins/mcreator-link` |

Also present (shared, not versioned generators): `mcreator-core`, `mcreator-localization`, `mcreator-themes`.

**Absent on this master (explicit gaps):**

- No `generator-26.2` / `neoforge-26.2*`
- No older Java generators for Forge/NeoForge **1.20.1**, **1.21.4**, or **1.21.8**

Converter target is **NeoForge 26.2**. Nearest official upstream generator shape is **`neoforge-26.1.2`**.

## 3. Ordered migration bands (converter)

Apply only bands whose destination is **strictly after** detected source (DET-002).

| Order | Band | Evidence | Converter executable |
|---|---|---|---|
| A | **1.20.1 residue** (Forge/MCreator) | No upstream generator on master; solved TOWW / Friend shapes | `srg-1.20.1` + `mechanical-java` + `mcreator-1.20.1` — ledger `dep_changes/mcreator/mcreator-1.20.1-to-26.2.md` |
| B | **1.21.1 upstream** | Official templates at `generator-1.21.1/neoforge-1.21.1` | Baseline MCreator NeoForge shape; ExactPrimer chain from 1.21.1 |
| C | **Mid-1.21.x via cases** (1.21.4 / 1.21.8…) | No generators on master; **CASE-003**, **REN-004**, LEARNINGS **Band A**, MOAdecor/Knocker in CASE-002 | ExactPrimer mid-chain + `Invoke-Mcreator1218ToNeoForge262Pass` + `Invoke-NeoForge26ApiRewritePass` |
| D | **26.1.x upstream** | Official templates at `generator-26.1.x/neoforge-26.1.2` | Short delta; BuildPaste/ChaosKit-style 26.1.2→26.2 |
| E | **26.2 via converter** | No MCreator generator yet; NeoForge/Minecraft 26.2 exact sources + primers | Final ExactPrimer `26.1→26.2` + Mel/API wave; installable jar proof in solved cases |

**Mel-style Band A (LEARNINGS):** CASE-003 (`mels_deco` 1.21.4→26.2) + REN-004 mechanical table. Typical failures: GUI `RenderSystem`, armor/tool constructors, ValueInput, `_level\w*` permissions, Optional NBT, `inventoryTick`/`ItemOwner`, `PacketDistributor`→`ClientPacketDistributor`.

## 4. High-signal chokepoints (paths under `_upstream/mcreator/plugins/...`)

Compare **1.21.1** ↔ **26.1.2** first; then close **26.1.2 → 26.2** with primers/converter (no generator-26.2).

### GUI

| Topic | 1.21.1 | 26.1.2 |
|---|---|---|
| Window blit / blend | `neoforge-1.21.1/templates/gui/gui_window.java.ftl` — `RenderSystem.enableBlend` / plain `blit` / `drawString` | `neoforge-26.1.2/templates/gui/gui_window.java.ftl` — `RenderPipelines.GUI_TEXTURED`, no RenderSystem blend |
| Client→server | `PacketDistributor.sendToServer` in `gui_window` / `gui_container` | `ClientPacketDistributor.sendToServer` |
| Messages | `templates/gui/gui_msg_*.java.ftl` — `CustomPacketPayload` + `StreamCodec` (both eras) | same pattern; keep server `PacketDistributor.sendToPlayer` |

### Packets / network

| Topic | Paths |
|---|---|
| Payload registration | `.../templates/modbase/mod.java.ftl` — `PayloadRegistrar` + `addNetworkMessage` (both) |
| Variables sync | `.../templates/modbase/variableslist.java.ftl` — AttachmentTypes + `PlayerVariablesSyncMessage` / `SavedDataSyncMessage`; 26.1.2 uses `ValueInput` / `TagValueInput` deserialize |
| GUI payloads | `.../templates/gui/gui_msg_{button,slot,slider,menustate}.java.ftl` |

### Procedures / triggers

| Topic | Paths |
|---|---|
| Procedure shell | `.../templates/procedure.java.ftl` |
| Procedure blocks | `.../procedures/*.ftl` (~551 @ 1.21.1, ~556 @ 26.1.2) |
| World/player triggers | `.../triggers/*.ftl` (65 each) — `@EventBusSubscriber` + NeoForge event hooks |
| AI tasks | `.../aitasks/*.ftl` |

Mid-1.21.x→26.2 procedure breakage is often **API inside** generated bodies (NBT Optional, permissions, item lifecycle), not missing trigger file names — use REN-004 / Band A.

### Overlays

| Topic | 1.21.1 | 26.1.2 |
|---|---|---|
| Overlay render | `neoforge-1.21.1/templates/overlay.java.ftl` — heavy `RenderSystem` + `drawString` | `neoforge-26.1.2/templates/overlay.java.ftl` — `RenderPipelines.GUI_TEXTURED` + `text()` |
| Definition | `overlay.definition.yaml` (both generators) |

### Registries / element inits

| Topic | Paths |
|---|---|
| Mod bootstrap | `.../templates/modbase/mod.java.ftl` — DeferredRegister wire-up |
| Blocks / items / menus / entities / … | `.../templates/elementinits/*.java.ftl` |
| Armor shape | 1.21.1: `templates/armor.java.ftl`; 26.1.2: `templates/armor/armor.java.ftl` + `armor_client.java.ftl` + `armor_equipment.json.ftl` (`.humanoidArmor`) |
| BlockEntity IO | `.../templates/block/blockentity.java.ftl` — 26.1.2 `loadAdditional(ValueInput)` |
| Block removal | `.../templates/block/block.java.ftl` — 26.1.2 `affectNeighborsAfterRemoval` |
| Game rules | `elementinits/gamerules.java.ftl` + definition YAML (mid-1.21 rewrite band) |

## 5. Explicit gaps

1. **No `generator-26.2`** on upstream master → final 26.2 MCreator shape is converter + NeoForge 26.2 sources, not an official FTL tree.
2. **No 1.20.1 / 1.21.4 / 1.21.8 generators** on this master → mid-band evidence is solved cases + ExactPrimer shards, not plugin diffs.
3. **26.1.2 ≠ 26.2** — still apply `26.1→26.2` primer / TriState / package moves after aligning to 26.1.2 templates.
4. Bedrock `generator-addon-26.1x` is out of scope for this NeoForge converter track.

## 6. How `dep_changes/mcreator` ledgers should cite this catalog

Converter tree: `RB-Legacy-Java-Converter/tools/lib/dep_changes/mcreator/`

| Ledger | Citation rule |
|---|---|
| `index.md` | Point **Station catalog** at this file; keep ordered bands A–E aligned with §3 |
| `mcreator-1.20.1-to-26.2.md` | Note missing Forge 1.20.1 generator; link catalog §2 gaps + §3 band A |
| `mcreator-1.21.x-to-26.2.md` | Row `mc-121-generator-1211` → catalog §2/`neoforge-1.21.1`; `mc-121-generator-261` → §2/`neoforge-26.1.2`; `mc-121-no-generator-262` → §5; Provenance → CASE-003 / REN-004 / LEARNINGS Band A + this catalog |

**Stable wording for change rows:**

- `evidence` kind → absolute or repo-relative path under `_upstream/mcreator/plugins/...` plus commit `1140e7457`
- `gap` kind → “No MCreator generator-26.2; see MCreator-generator-delta-catalog.md §5”
- Do not treat catalog rows as executable; executable column stays `mcreator-1.21.x` / `neoforge-26-api` / ExactPrimer IDs

**Related:**

- LEARNINGS Band A: `LEARNINGS-2.0.x-handwritten-neoforge.md`
- CASE-003 / REN-004: Mel 1.21.4 reference
- Station primers: `knowledge/NeoForge_Primers/26.2/primer_changes_*-to-26.2.md`
- Upstream STATUS: `knowledge/_upstream/mcreator/_STATUS.json`
