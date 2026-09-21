# DET-001 — Detect source, then apply only the needed primer path

## Symptom

Wrong migration intensity: e.g. heavy Forge 1.20.1 SRG passes on a NeoForge 1.21.x jar, or missing 26.2 client rules.

## Solution

1. `Get-SourceProfile` → `SOURCE_PROFILE.json` (version, loader, route, passes, evidence).
2. `Get-PrimerMigrationChain` / `Get-PrimerMigrationRules` from `tools/lib/PrimerChangeIndex.json`.
3. `Invoke-ExactPrimerMigrationRules` applies cumulative **rule IDs** after the detected source.
4. `Test-MigrationPass` gates broad PowerShell passes by route.

Station evidence ledgers (MCP-friendly):

`knowledge/NeoForge_Primers/26.2/primer_changes_<source>-to-26.2.md`

## Verify

Intake log line resembles:

`Intake : loader=neoforge source=1.21.1 confidence=high route=neoforge-1.21.x`

`PRIMER_CHANGE_INDEX.md` starts at the detected source.

## Related

See **DET-002** for the strictly-after-source primer chain policy (Mel's DeCo / 1.21.4).

