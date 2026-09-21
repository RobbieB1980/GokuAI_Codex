# Decompile report

- Jar: F:\GrokBuild Working Folder\MOA Mods\MOAdecor SCIENCE 1.21.8.A.jar
- Output: F:\GrokBuild Working Folder\MOA Mods\MOAdecor SCIENCE 1.21.8.A-decompiled
- Generated: 2026-08-01 10:44
- Vineflower: 1.12.0
- Java: C:\Program Files\Microsoft\jdk-25.0.4.7-hotspot\bin\java.exe

## Detected metadata

| Field | Value |
|-------|-------|
| Loader | neoforge |
| mod_id | moa_science |
| Name | MOA: SCIENCE |
| Version | 1.21.8. |
| MC hint |  |
| Mixins | False |
| Java files | 155 |

## Notes

- (none)

## Pipeline

1. Done: jar extract + decompile + src layout
2. Optional: run Convert-Forge1201-ToNeoForge262.ps1 on this folder to scaffold NeoForge 26.2
3. Manual: fix decompile artifacts, deps, mixins, datapacks, GeckoLib paths, etc.

## Limits

- Decompiled code is imperfect (generics, lambdas, switch, records).
- Obfuscated jars may be unreadable.
- Fabric/Quilt jars are extracted but the Legacy Converter targets Forge/NeoForge APIs.
- Original jar is never modified.
