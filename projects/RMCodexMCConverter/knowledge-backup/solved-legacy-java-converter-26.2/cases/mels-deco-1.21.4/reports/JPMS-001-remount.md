# JPMS remount report — Mel's DeCo + NextGen Furniture (2026-08-29)

## Error
Modules mels_deco and next_genfurniture export package rb.legacy.converter.compat to module jei

## Fix
- Converter: Get-Legacy262CompatPackage / Convert-NeoForge262ApiMoves -ModId / Invoke-MechanicalJavaRewrites -ModId
- Mel: unused Legacy262Compat removed; jar has no rb/ entries
- NextGen: package rb.legacy.converter.compat.nextgen_furniture; clean rebuild

## Installed
%APPDATA%\.minecraft\versions\neoforge-26.2.0.72\mods\
- mels_deco-1.2+mc26.2-neoforge.jar (clean, no rb/)
- nextgen_furniture-0.0.9-beta+mc26.2-neoforge.jar (scoped compat)

## Knowledge
JPMS-001-legacy262compat-mod-scoped-package.md + CASE-001/003/REN-004/catalog/SolvedConversionIndex updates
