# REG-001 — Runtime `Block id not set` (Supplier registerBlock helper)

## Symptom

NeoForge 26.2 crashes while registering blocks:

`Block id not set` / similar Item id failures for custom helpers.

## Detection

Java like:

```java
private static <T extends Block> DeferredBlock<T> registerBlock(String name, Supplier<T> block) {
    DeferredBlock<T> toReturn = BLOCKS.register(name, block);
    ...
}
// call sites:
registerBlock("chair_white", () -> new ChairBlock(Properties.of().strength(...)));
```

Seen on NextGen Furniture `ModBlocks`.

## Solution

`Convert-CustomBlockRegistrationText` (ConversionCore) via `Invoke-BlockItemIdPass`:

- `Supplier<T>` → `Function<Properties, T>`
- `BLOCKS.register(name, block)` → `BLOCKS.registerBlock(name, block)`
- `() -> new Foo(Properties.of()...)` → `properties -> new Foo(properties...)`
- paired `ITEMS.register(...)` → `ITEMS.registerItem(...)`

Idempotent: second run no-ops once Supplier signature is gone.

## Verify

- `ModBlocks` uses `Function<Properties, T>` and `registerBlock`
- `gradlew build` succeeds
- Client/server load no longer throws Block id not set on registry freeze

## Proven on

[CASE-001](CASE-001-nextgen-furniture-1.21.1-success.md) — successful 1.21.1 Nextgen convert uses `properties -> new ChairBlock(properties.strength(...))`.
