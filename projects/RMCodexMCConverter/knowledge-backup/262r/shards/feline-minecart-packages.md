# Shard — FelineModel split + minecart/boat packages (catfighting)

**Proven:** Cat Fighting NeoForge 1.21.10 → 26.2 compile-green repair (2026-09-05)

Source cue: `1.21.10` / `1.21.x` handwritten NeoForge with feline model mixins and minecart ride/push mixins.

## Detect → target

| ID | Detect | Target (exact 26.2) |
|---|---|---|
| `mc-262r-minecart-package` | `world.entity.vehicle.AbstractMinecart` (+ Minecart*) | `world.entity.vehicle.minecart.*` |
| `mc-262r-boat-package` | `world.entity.vehicle.AbstractBoat` / `Boat` / `Raft` | `world.entity.vehicle.boat.*` |
| `mc-262r-feline-model-package` | `client.model.FelineModel` | package move to `client.model.animal.feline.FelineModel` (1.21.11) then 26.1 split |
| `mc-262r-feline-model-split` | `@Mixin(FelineModel)` + `createBodyMesh` | `@Mixin(AdultFelineModel)` — `createBodyMesh` lives on adult only |
| `mc-262r-feline-model-setupanim` | `@Mixin(FelineModel)` + `setupAnim` | `@Mixin({AdultFelineModel.class, BabyFelineModel.class})` |
| `mc-262r-feline-model-abstract` | bare `FelineModel` type refs | `AbstractFelineModel` (26.1; not 1:1) |
| `mc-262r-mixin-descriptor-slash` | mixin `method = "...Lnet/minecraft/world/entity/animal/Cat;..."` | slash form must follow FQN remaps (`…/animal/feline/Cat`) |
| `mc-262r-mixin-this-instanceof` | `@Mixin` file with `this instanceof Cat` | `(Object) this instanceof Cat` |

## Evidence

- Primer ledger (nearest-older for 1.21.10): `primer_changes_1.21.8-to-26.2` → shard `1.21.11.md` vehicle/model package rows
- 26.1 primer: `FelineModel` → `AbstractFelineModel` with `AdultFelineModel` / `BabyFelineModel`
- Physical 26.2 sources jar: `net/minecraft/client/model/animal/feline/AdultFelineModel.java` (`createBodyMesh`), `…/AbstractFelineModel.java`, `…/vehicle/minecart/AbstractMinecart.java`

## Converter encoding

- Packages + slash descriptors + FelineModel split: `Invoke-MinecraftEntitySubpackageRemapPass`
- Mixin `this instanceof`: `Invoke-Minecraft262CompileRepairPass`

## Do not

- Do not invent a permanent client renderer compile-gate for unfinished Entity Render State work.
- Do not map every `FelineModel` use to `AdultFelineModel` — baby setupAnim / abstract field holders need Adult+Baby or `AbstractFelineModel`.
