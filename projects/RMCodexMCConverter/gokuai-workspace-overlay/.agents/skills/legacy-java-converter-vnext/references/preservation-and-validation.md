# Preservation and validation checklist

Compare source and output rather than checking only whether output files exist.

## Preserve or convert

- textures, sounds, language files, shaders, particles, and pack metadata;
- blockstates, block/item/entity models, animations, and renderer bindings;
- recipes, loot, tags, advancements, world generation, structures, and data;
- blocks, items, tabs, menus, screens, effects, enchantments, and networking;
- entities, attributes, spawn rules, goals, targeting, navigation, interactions,
  persistence, synchronization, and custom behaviour;
- dependencies, access transformers/wideners, mixins, services, and metadata.

## Manifest categories

Record independent source/destination counts, missing entries, and evidence
paths for `assets`, `models`, `items`, `entities`, and `aiBehavior`.

## Validation gates

1. `build`: JDK 25 full Gradle build succeeds and produces the intended jar.
2. `launch`: NeoForge starts and remains alive through the smoke window.
3. `registryData`: registries, resources, and data load cleanly.
4. `content`: representative assets, models, blocks, items, and entities appear.
5. `behavior`: AI, interactions, persistence, networking, and key mechanics
  match the original mod as closely as the target APIs permit.

Each gate is `passed`, `failed`, `not_tested`, or `not_applicable`, with evidence
and notes. A clean build sets only `build`; it never implies launch, content, or
behavior. Record unperformed gates as `not_tested`, never passed.
