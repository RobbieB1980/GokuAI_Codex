# Shard — FlyingMob / FlyingAnimal removed

**IDs:** `mc-262r-flying-mob-removed`, `mc-262r-flying-animal-removed`  
**Primers:** 1.21.6 (`FlyingMob` → travelFlying), 26.2 (`FlyingAnimal` → `Entity#omnidirectionalAirMover`)  
**Proven:** Easy Mob Farm

## Detect

```java
import net.minecraft.world.entity.FlyingMob;
import net.minecraft.world.entity.animal.FlyingAnimal;
entity instanceof FlyingMob
entity instanceof FlyingAnimal fa && fa.isFlying()
```

## Target (leaf heuristic)

Replace instanceof checks with concrete flyers still present in 26.2:

- `Ghast`, `HappyGhast` (`animal.happyghast`), `Phantom`
- `Bee` + `bee.isFlying()` (Bee no longer implements FlyingAnimal; `isFlying()` remains)

`omnidirectionalAirMover()` is **protected** on Entity — not usable from external helpers.

## Converter encoding

`Invoke-Minecraft262CompileRepairPass` rewrites `instanceof FlyingMob` / `FlyingAnimal` (+ `isFlying()`) to the leaf heuristic above and injects Ghast / HappyGhast / Phantom / Bee imports.
