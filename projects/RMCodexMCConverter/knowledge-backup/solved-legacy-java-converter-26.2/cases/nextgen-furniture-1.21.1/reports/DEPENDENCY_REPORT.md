# Dependency report

Generated: 2026-08-29 21:26

The converter reads `mods.toml` / `neoforge.mods.toml`, Gradle coordinates, jar-in-jar metadata, and Java imports.
Official NeoForge 26.2 artifacts are downloaded. Required mods with no 26.2 build are decompiled and converted.

| Mod ID | Required | Action | Status | Detail |
|--------|----------|--------|--------|--------|
| minecraft | True | skip | platform | Minecraft/loader platform dep |
| neoforge | True | skip | platform | Minecraft/loader platform dep |
| fusion | True | modrinth | downloaded | Official 26.2 neoforge jar from Modrinth 1.3.14-neoforge-mc26.2 jar=fusion-1.3.14-neoforge-mc26.2.jar |

## Gaps

- None recorded.

## Detected (pre-resolve)

- minecraft required=True source=toml [1.21.1]
- neoforge required=True source=toml [21.1.217,)
- fusion required=True source=toml [1.0.0,)
