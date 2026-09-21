# Converter — import-detected libraries

**Pass:** `Read-ImportDetectedLibraries` in `ModDependencyPipeline.ps1`  
**ID:** `mc-262r-dep-import-detect`

## Rule

Catalog `imports` prefixes (e.g. `mezz.jei`) are scanned under `src/main/java` with **literal** `Select-String -SimpleMatch`.

## Do not

```powershell
# WRONG — Escape + SimpleMatch looks for literal "mezz\.jei"
Select-String -Pattern ([regex]::Escape($pat)) -SimpleMatch
```

## Do

```powershell
Select-String -Pattern $pat -SimpleMatch -List
```

Import hits are marked `Required = $true` / `Source = 'import'` so dual-pull runs even when toml omitted the soft dep.

## Catalog examples

| Import prefix | modId |
|---|---|
| `mezz.jei` | `jei` |
| `software.bernie.geckolib` / `com.geckolib` | `geckolib` |
| `tschipp.carryon` | carry-on aliases |
