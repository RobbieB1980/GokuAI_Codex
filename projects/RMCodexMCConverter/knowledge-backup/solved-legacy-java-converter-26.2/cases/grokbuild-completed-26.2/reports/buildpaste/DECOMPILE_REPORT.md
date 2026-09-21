# Decompile report

- Jar: F:\GrokBuild Working Folder\Buildpaste\BuildPaste_NeoForge-26.1.2v2.2.1.jar
- Output: F:\GrokBuild Working Folder\Buildpaste\BuildPaste_NeoForge-26.1.2v2.2.1-decompiled
- Generated: 2026-08-01 08:49
- Vineflower: 1.12.0
- Java: C:\Program Files\Microsoft\jdk-25.0.4.7-hotspot\bin\java.exe

## Detected metadata

| Field | Value |
|-------|-------|
| Loader | neoforge |
| mod_id | buildpaste |
| Name | BuildPaste |
| Version | 2.2.1 |
| MC hint |  |
| Mixins | False |
| Java files | 53 |

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
