# Shard — Map.Entry property()/value() false rewrite

**ID:** `mc-262r-map-entry-getkey`  
**Proven:** Easy Mob Farm

## Detect

```java
for (var entry : map.entrySet()) {
   entry.property(); // WRONG
   entry.value();    // WRONG
}
```

Often introduced when a mechanical pass confuses codec `MapCodec` field names with `Map.Entry`.

## Target

```java
entry.getKey();
entry.getValue();
```

## Do not rewrite

- `Holder.value()`
- BlockState `Property` / `property.value()`
- Record component accessors that are genuinely named `property`/`value`
