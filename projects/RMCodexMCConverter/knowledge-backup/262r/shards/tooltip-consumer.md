# Shard — appendHoverText Consumer<Component>

**ID:** `mc-262r-tooltip-consumer`  
**Proven:** Easy Mob Farm

## Detect

```java
void appendHoverText(..., List<Component> tooltip, ...)
tooltip.add(component);
void addTooltip(List<Component> tooltip, Component c)
```

## Target

```java
void appendHoverText(..., Consumer<Component> tooltip, TooltipFlag)
tooltip.accept(component);
void addTooltip(Consumer<Component> tooltip, Component c) { tooltip.accept(...); }
```

GuiGraphicsExtractor tooltips:

| Old | New |
|---|---|
| `renderComponentTooltip(font, list, x, y)` | `setComponentTooltipForNextFrame(font, list, x, y)` |
| `extractTooltip(font, formatted, x, y)` | `setTooltipForNextFrame(font, formatted, x, y)` |
