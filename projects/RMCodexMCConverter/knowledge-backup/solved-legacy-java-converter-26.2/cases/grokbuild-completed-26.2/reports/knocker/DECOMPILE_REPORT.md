# Decompile report

- Jar: F:\Grok Build Apps\1\the_knocker-1.5.2-neoforge-1.21.8.jar
- Output: F:\Grok Build Apps\1\the_knocker-1.5.2-neoforge-1.21.8-decompiled
- Generated: 2026-07-25 19:54
- Vineflower: 1.12.0
- Java: C:\Program Files\Microsoft\jdk-25.0.3.9-hotspot\bin\java.exe

## Detected metadata

| Field | Value |
|-------|-------|
| Loader | neoforge |
| mod_id | the_knocker |
| Name | The Knocker |
| Version | 1.5.2 |
| MC hint |  |
| Mixins | False |
| Java files | 59 |

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
