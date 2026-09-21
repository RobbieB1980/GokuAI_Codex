# Shard — EntityType.byString removed

**ID:** `mc-262r-entitytype-bystring`  
**Proven:** Easy Mob Farm

## Detect

`EntityType.byString(name)` / `EntityType.byString(id.toString())`

## Target

```java
BuiltInRegistries.ENTITY_TYPE.getOptional(Identifier.parse(name)).orElse(null);
// when already an Identifier:
BuiltInRegistries.ENTITY_TYPE.getOptional(id).orElse(null);
```

Ensure imports: `BuiltInRegistries`, `Identifier`.

`Registry.getOptional(Identifier)` returns `Optional<T>` (entity type), not Holder — no `.map(h -> h.value())` needed.
