# The One Who Watches — NeoForge 26.2 Migration Workspace

Playable NeoForge port of **The One Who Watches** (Pixel Coder / MCreator, originally Forge 1.20.1).

## Status

**Slices 1–6 complete** for a loadable, testable mod:

- Content registries, entities, GeckoLib models  
- Stage/fear world data + client sync  
- Natural spawns, entity ticks, jumpscare overlay  
- Structure worldgen, meat effects, sleep interruption  

This is **not** a perfect line-by-line port of every MCreator procedure. See `MIGRATION_STATUS.md`.

## Requirements

- **Java 25** JDK (`JAVA_HOME`)
- NeoForge **26.2.0.64**
- **GeckoLib** 5.5.3 for Minecraft 26.2 (required)

## Build / run

```powershell
.\gradlew.bat build
.\gradlew.bat runClient
```

Output JAR:

```text
build\libs\the_one_who_watches-1.4.4+mc26.2-neoforge.1.jar
```

## Useful commands

| Command | Effect |
|---------|--------|
| `/settowwstage 4` | Set stage + enable natural spawn |
| `/getfear` / `/setfear N` | Read/write fear |
| `/settowwcanspawn true` | Force spawn flag |
| `/CanSpawnBlood true` | Blood trail toggle |
| `/summon the_one_who_watches:toww_staring` | Force entity |

## Folder guide

- `src/main/java` — active NeoForge code  
- `src/main/resources` — assets, data, structures  
- `legacy-source` — original decompiled Forge (reference only)  
- `legacy-resources` — quarantined 1.20.1 datapack  
- `tools` — audit helpers  

## License

See original mod license / `Academic Free License v3.0` in `gradle.properties`.
