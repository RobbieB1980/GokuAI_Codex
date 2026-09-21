# Learnings 2.0.x — Hand-written NeoForge mods → 26.2

Audience: **Grok/xAI agents**, **RMBLocalAIStation**, and **Java Minecraft modders** converting NeoForge **1.21.x** (and Forge 1.20.1) code to **NeoForge 26.2**.

Public converter: https://github.com/RobbieB1980/LegacyJavaConverter (release **2.0.4+**)

## Why this exists

MCreator-shaped mods (Mel's DeCo) and hand-written DFU-heavy mods (MedSystem / TarkovCraft) fail in **different** ways. Encoding both bands into the converter means the next person does not rediscover 90–250 compile errors by hand.

## Decision tree

```text
Is there an official NeoForge 26.2 jar for this mod?
  YES → prefer official for play; still keep converter path for when official is absent
  NO  → Mode B (jar) or Mode A (project) through RB Legacy Java Converter

After scaffold:
  SolvedConversionIndex match? → overlays + forced passes auto-apply
  Soft optional integrations (Carry On / Sable / JEI)? → INT-001 exclude
  RecordCodecBuilder / mixin Vineflower mess? → DFU-001
  Overlay applied but errors look like pre-DFU? → OVY-001 (overlay was bad)
  GUI still shows old version after tool updates? → PKG-002
```

## Band A — MCreator / Mel-style (CASE-003, REN-004)

Typical: GUI `RenderSystem`, armor/tool item constructors, ValueInput, permissions `_level\w*`, Optional NBT, inventoryTick/ItemOwner, PacketDistributor.

Encoded in ExactPrimer + `Invoke-NeoForge26ApiRewritePass` + `Invoke-Mcreator1218ToNeoForge262Pass` (converter **2.0.2**).

## Band B — Hand-written DFU / records / mixins (CASE-004, DFU-001)

Typical: `RecordCodecBuilder` inference to `Object`, record field access in `.validate`, mixin `(T)this`, soft-dep Integration folders, Vineflower leftover util classes that already live in a required core jar.

Encoded in `Invoke-DfuCodecRepairPass` + soft-dep exclude + **green** overlay zip (converter **2.0.3 / 2.0.4**).

## Overlay contract (critical)

Overlays run **after** mechanical/DFU passes. Therefore:

| Overlay content | Result |
|---|---|
| Green tree that already builds | Reconvert stays green |
| Author-oracle / broken decompile | Silently undoes DFU; ~90 errors return |

Always ship `DELETE.txt` + synced `*.mixins.json` with the overlay (OVY-001).

## Prefer official jars when present

Example: MedSystem official `2.13.0+26.2` for play when available. Converter CASE-004 proves uplift of `2.12.1+1.21.1` when official 26.2 is missing — that is the product value for the community.

## Release hygiene

Bump **GUI + Setup csproj versions** and rebuild Setup (PKG-002). Updating only PowerShell under AppData leaves the window title on an old release and confuses users.

## Verification bar

Success for packaging claims:

1. `gradlew build` exit 0
2. Installable `build/libs/*.jar`
3. Prefer in-game load on NeoForge **26.2.0.72** with required deps

Mode B scaffold-without-green-build is allowed as a **partial** outcome (exit 2) but must not be marketed as installable.

## Index of deep dives

| ID | Topic |
|---|---|
| CASE-003 | Mel's DeCo 1.21.4 success |
| CASE-004 | MedSystem 1.21.1 success + 2.0.4 overlay fix |
| REN-004 | Mel mechanical rule table |
| DFU-001 | RecordCodecBuilder / validate / mixin |
| OVY-001 | Overlay must be green |
| INT-001 | Soft-dep integration exclude |
| JPMS-001 | Mod-scoped Legacy262Compat package |
| PKG-001 / PKG-002 | Installer payload + version bump |
