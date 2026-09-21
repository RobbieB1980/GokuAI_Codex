# Converter — ItemHandler.BLOCK registerBlockEntity stub

**Pass:** NeoForge 26 API / mechanical capability stub in `Convert-Forge1201-ToNeoForge262.ps1`  
**ID:** `mc-262r-itemhandler-block-stub`

## Detect

```java
event.registerBlockEntity(ItemHandler.BLOCK, ...);
// or Vineflower multiline:
event.registerBlockEntity(
   ItemHandler.BLOCK, ...
);
```

## Target

Comment out the **whole call** (including closing `);`). Single-line-only replace leaves orphan `);` → `illegal start of expression`.

Also clean leftover:

```java
// TODO 26.2: ...
);
```

## Proven

Easy Mob Farm `ModBlockCapabilities.java` (2026-09-05) — first compile gate was orphan `);` after stub.
