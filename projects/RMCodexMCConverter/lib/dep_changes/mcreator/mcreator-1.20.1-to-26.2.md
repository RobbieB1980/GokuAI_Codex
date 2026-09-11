# MCreator / Forge 1.20.1 residue → NeoForge 26.2

| Change ID | Kind | Summary | Executable |
|---|---|---|---|
| `mc-1201-srg-cleanup` | renamed | SRG `m_/f_` → official names | `srg-1.20.1` |
| `mc-1201-forge-neoforge-pkg` | moved | `net.minecraftforge` → NeoForge packages | `mechanical-java` |
| `mc-1201-tick-events` | replaced_by | legacy TickEvent → Client/ServerTickEvent.Post | `mechanical-java` |
| `mc-1201-geckolib4` | replaced_by | Often co-occurs with GeckoLib 4 | see `dep_changes/geckolib` |
| `mc-1201-mcreator-residue` | behavioral | MCreator Forge 1.20.1 helpers / procedures | `mcreator-1.20.1` |

## Upstream note

Current MCreator master does **not** ship a Forge 1.20.1 generator plugin. Use converter passes + solved cases (TOWW) until an archived generator is mirrored.
