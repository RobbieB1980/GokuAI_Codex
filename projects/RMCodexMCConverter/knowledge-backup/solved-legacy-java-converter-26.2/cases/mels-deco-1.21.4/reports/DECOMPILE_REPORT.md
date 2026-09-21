# Decompile report

- Jar: C:\Users\rmbel\Downloads\1.21.4 Mel's DeCo v1.2.jar
- Output: C:\Users\rmbel\Downloads\1.21.4 Mel's DeCo v1.2-decompiled
- Generated: 2026-08-29 23:58
- Vineflower: 1.12.0
- Java: C:\Program Files\Eclipse Adoptium\jdk-25.0.4.101-hotspot\bin\java.exe

## Detected metadata

| Field | Value |
|-------|-------|
| Loader | neoforge |
| mod_id | mels_deco |
| Name | Mel's DeCo |
| Version | 1.2 |
| MC hint |  |
| Detected source MC | 1.21.4 |
| Detection confidence | high |
| Migration route | neoforge-1.21.x |
| Mixins | False |
| Java files | 1798 |
| Resource files | 11215 |
| PNG textures | 1090 |
| Sounds | 124 |
| Geo models | 0 |
| Animations | 0 |
| Block/item models | 4086 |
| Blockstates | 1144 |
| Structures (nbt) | 0 |
| Declared deps | 2 |

## Notes

- Declared dependencies: neoforge, minecraft

## Pipeline

1. Done: jar extract + decompile + src layout
2. Optional: run Convert-Forge1201-ToNeoForge262.ps1 on this folder to scaffold NeoForge 26.2 (reads detected-dependencies.json, downloads official 26.2 artifacts, converts remaining required mods)
3. Manual: fix decompile artifacts, mixins, datapacks, GeckoLib paths, remaining compile errors.

## Limits

- Decompiled code is imperfect (generics, lambdas, switch, records).
- Obfuscated jars may be unreadable.
- Fabric/Quilt jars are extracted but the Legacy Converter targets Forge/NeoForge APIs.
- Original jar is never modified.
