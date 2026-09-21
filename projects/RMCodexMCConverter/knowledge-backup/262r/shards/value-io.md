# Shard — ValueInput / ValueOutput (block entity + entity NBT)

**IDs:** `mc-262r-value-io-be`, `mc-262r-value-io-entity-load`  
**Proven:** Easy Mob Farm 1.21.4 → 26.2

## BlockEntity

| Detect | Target |
|---|---|
| `saveAdditional(CompoundTag, Provider)` | `saveAdditional(ValueOutput)` |
| `loadAdditional(CompoundTag, Provider)` | `loadAdditional(ValueInput)` |
| `ContainerHelper.saveAllItems(CompoundTag, …)` | `ContainerHelper.saveAllItems(ValueOutput, …)` |
| `input.contains("Key")` | use `getIntOr` / `getStringOr` / `read(...).isPresent()` — ValueInput has no `contains` |
| `putUUID` / `getUUID` | `output.store("Owner", UUIDUtil.CODEC, uuid)` / `input.read("Owner", UUIDUtil.CODEC)` |
| `this.level()` on BlockEntity | `this.getLevel()` (field was wrongly rewritten to method) |
| `getUpdateTag` + manual saveAllItems | prefer `saveCustomOnly(provider)` |

## Entity

| Detect | Target |
|---|---|
| `entity.load(CompoundTag)` | `entity.load(TagValueInput.create(ProblemReporter.DISCARDING, registryAccess, tag))` |
| `livingEntity.readAdditionalSaveData(tag)` | **protected** — use public `entity.load(ValueInput)` instead |
| `livingEntity.saveWithoutId(CompoundTag)` | `TagValueOutput.createWithContext(...); saveWithoutId(out); tag = out.buildResult()` |

## Evidence

- `net.minecraft.world.level.storage.ValueInput` / `ValueOutput` / `TagValueInput` / `TagValueOutput`
- `net.minecraft.core.UUIDUtil.CODEC`
