# ItemStack before components bound (26.2)

**ID:** `mc-262r-itemstack-components-bound`

## Symptom
`NullPointerException: Components not bound yet` at `Holder$Reference.components` → `ItemStack.<init>` during mod load / `FMLClientSetupEvent` / static `<clinit>`.
Often wrapped as `ExceptionInInitializerError` then `ModLoadingException`.

## Why
26.2 `ItemStack` reads bound data components from the item `Holder`. Static maps of `ItemStack` and FMLClientSetup deferred config that construct stacks are too early.

## Hardened remap
1. Store defaults as item id strings + counts (`minecraft:leather::1`), never `new ItemStack` in `static {}`.
2. Do not force ItemStack materialization on `FMLClientSetupEvent`.
3. Lazy-load / register config on first gameplay use (`ensureRegistered()`), or on `ServerStarting` (components bound).
4. Prefer `minecraft:white_wool` string over colored-item API helpers in static defaults.

## Proven
CASE-006 Easy Mob Farm `MobFarmBonusConfig.<clinit>` — crash-2026-09-05_12.11.12-client.txt (NeoForge 26.2.0.72).

---

# Related: block models with `minecraft:item/*` fail inventory bake

**ID:** `mc-262r-item-atlas-in-block-model`

**Symptom:** `Rejecting block model … contains sprites from outside of supported atlas` then `Unable to bake item model` / purple-black creative icons.

**Why:** 26.2 item bake rejects `minecraft:item/...` textures inside block models used by `assets/.../items/*.json`.

**Fix:** In block/templates used as item models, replace `minecraft:item/*` with `minecraft:block/*` (or mod block textures). Keep `#texture` keys; change paths only.

**Proven:** CASE-006 Easy Mob Farm animal/iron_golem/monster farm templates (2026-09-05).
