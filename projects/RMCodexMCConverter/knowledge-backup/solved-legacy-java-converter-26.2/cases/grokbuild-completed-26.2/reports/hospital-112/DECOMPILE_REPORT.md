# Decompile report

- Jar: F:\GrokBuild Working Folder\Hospital\Hospital Mod 1.12.2 (14.23.5.2768).jar
- Output: F:\GrokBuild Working Folder\Hospital\Hospital Mod 1.12.2 (14.23.5.2768)-decompiled
- Generated: 2026-08-01 11:35
- Vineflower: 1.12.0
- Java: C:\Program Files\Microsoft\jdk-25.0.4.7-hotspot\bin\java.exe

## Detected metadata

| Field | Value |
|-------|-------|
| Loader | forge-1.12 |
| mod_id | the_hospital_mod |
| Name | The Hospital Mod |
| Version | 1.0.0 |
| MC hint | 1.12.2 |
| Mixins | False |
| Java files | 147 |

## Notes

- mcmod.info found (Forge 1.12.x / legacy).
- authors: Leon90, MCreator

## Pipeline

1. Done: jar extract + decompile + src layout
2. Optional: run Convert-112ToNeoForge262.ps1 on this folder to scaffold NeoForge 26.2
3. Manual: fix decompile artifacts, deps, mixins, datapacks, GeckoLib paths, etc.

## Limits

- Decompiled code is imperfect (generics, lambdas, switch, records).
- Obfuscated jars may be unreadable.
- Fabric/Quilt jars are extracted but this converter targets Forge 1.12 -> NeoForge APIs.
- Original jar is never modified.
