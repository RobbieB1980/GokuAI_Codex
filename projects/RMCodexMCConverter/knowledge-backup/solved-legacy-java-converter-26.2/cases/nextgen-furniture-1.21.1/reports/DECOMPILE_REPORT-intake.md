# Decompile report

- Jar: C:\Users\rmbel\Downloads\1.21.1-nextgen_furniture_neoforge+1.21.1-0.0.9-beta.jar
- Output: C:\Users\rmbel\Downloads\1.21.1-nextgen_furniture_neoforge+1.21.1-0.0.9-beta-decompiled
- Generated: 2026-08-29 21:26
- Vineflower: 1.12.0
- Java: C:\Program Files\Eclipse Adoptium\jdk-25.0.4.101-hotspot\bin\java.exe

## Detected metadata

| Field | Value |
|-------|-------|
| Loader | neoforge |
| mod_id | nextgen_furniture |
| Name | NhatJS's Next-Gen Furniture Mod |
| Version | 0.0.9-beta |
| MC hint |  |
| Detected source MC | 1.21.1 |
| Detection confidence | high |
| Migration route | neoforge-1.21.x |
| Mixins | False |
| Java files | 69 |
| Resource files | 666 |
| PNG textures | 93 |
| Sounds | 0 |
| Geo models | 0 |
| Animations | 0 |
| Block/item models | 234 |
| Blockstates | 86 |
| Structures (nbt) | 0 |
| Declared deps | 3 |

## Notes

- Declared dependencies: neoforge, minecraft, fusion

## Pipeline

1. Done: jar extract + decompile + src layout
2. Optional: run Convert-Forge1201-ToNeoForge262.ps1 on this folder to scaffold NeoForge 26.2 (reads detected-dependencies.json, downloads official 26.2 artifacts, converts remaining required mods)
3. Manual: fix decompile artifacts, mixins, datapacks, GeckoLib paths, remaining compile errors.

## Limits

- Decompiled code is imperfect (generics, lambdas, switch, records).
- Obfuscated jars may be unreadable.
- Fabric/Quilt jars are extracted but the Legacy Converter targets Forge/NeoForge APIs.
- Original jar is never modified.
