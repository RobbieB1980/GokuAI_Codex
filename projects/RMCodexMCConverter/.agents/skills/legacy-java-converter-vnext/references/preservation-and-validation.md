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

## Validation gates

1. Structural: expected source/resources and manifest inventory are present.
2. Static: no unresolved placeholders, disabled features, or silent drops.
3. Build: JDK 25 full Gradle build succeeds and produces the intended jar.
4. Load: NeoForge starts and registries, resources, and data load cleanly.
5. Content: representative assets, models, blocks, items, and entities appear.
6. Behaviour: AI, interactions, persistence, networking, and key mechanics
   match the original mod as closely as the target APIs permit.

Record unperformed gates as unverified, never passed.
