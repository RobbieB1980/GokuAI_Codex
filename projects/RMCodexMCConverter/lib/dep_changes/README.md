# Dependency incremental change ledgers

Converter-owned evidence for hard deps detected on the source mod.

| Track | When attached | Executable pass |
|---|---|---|
| `geckolib/` | GeckoLib 4 imports / catalog match | `geckolib` (`Invoke-GeckoLib26Pass`) |
| `mcreator/` | `net.mcreator.` / Framework=mcreator | `mcreator-1.20.1` / `mcreator-1.21.x` |

These ledgers are **advisory evidence** with stable change IDs. They do not replace the PowerShell rewrite passes.

262-repair remaps (compile + in-game leftovers) are indexed for retrieval outside this converter at `C:\gokuai\Data\262r` (MCP category `262r`, version `26.2`).

Station MCreator upstream (not shipped here): `C:\gokuai\Data\_upstream\mcreator`  
Catalog: `knowledge/Solved_Problems/legacy-java-converter-26.2/MCreator-generator-delta-catalog.md`
