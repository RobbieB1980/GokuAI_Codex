# RB 26.2 → 26.3 Converter Preview

This is a separate target package for converting an existing NeoForge 26.2
project toward Minecraft/NeoForge 26.3. The established legacy converter remains
the supported Forge/NeoForge → NeoForge 26.2 product.

The preview currently performs only deterministic, evidence-backed changes:

- validates an exact NeoForge 26.2 source;
- copies to a new output directory;
- updates exact Minecraft version markers when present;
- updates `pack.mcmeta` using the 26.3 data/resource pack versions;
- migrates the safe `surface_rule` → `material_rule` worldgen rename;
- moves the documented noise-router aquifer fields when the source shape is unambiguous;
- writes a conversion manifest and migration evidence report;
- flags renderer/client API, ambiguous worldgen, and dependency work for AST/Codex repair.

The target does not silently invent a stable NeoForge 26.3 dependency pin. The
official target pin must be supplied with `-NeoVersion` until NeoForge publishes
the stable 26.3 artifact.

```powershell
& .\targets\rb-26.2-to-26.3\Convert-RB262To263.ps1 `
  -InputPath C:\mods\my-mod-26.2 `
  -OutputPath C:\mods\my-mod-26.3 `
  -NeoVersion '<official-26.3-neoforge-version>'
```

Build success, client launch, registry/data loading, and gameplay behavior are
separate validation gates. This preview does not claim a complete 26.3 port.
