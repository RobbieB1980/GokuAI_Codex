# DET-002 — Primer chain: destination strictly after source

## Symptom

Unknown sources replayed the entire 1.20.1→26.2 primer list, or equal/below primers were applied to an already-newer jar.

## Solution

`Get-PrimerMigrationChain` in `tools/lib/ConversionCore.ps1`:

1. Normalize version; unknown/unranked → empty chain.
2. Already `26.2*` → empty.
3. Year-numbered `22.x`–`26.1` → only deltas with `to > 26.1` (final 26.1→26.2).
4. Otherwise include transitions where **`to` rank > source rank** (never equal/below).

`PRIMER_CHANGE_INDEX.md` text states this policy explicitly.

## Verify

| Source | Expected first transition |
|---|---|
| 1.21.4 | 1.21.4→1.21.5 |
| 1.21.9 | 1.21.9→1.21.10 (no →1.21.9) |
| 22.1 | 26.1→26.2 only |
| 1.19.2 | empty |
