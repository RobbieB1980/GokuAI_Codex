# Primer change quick reference

Detected source: **1.21.1**; target: **26.2**; route: `neoforge-1.21.x`.

This is a condensed change index, not a replacement for the linked official primers. Only transitions after the detected source are included.

## 1.21.1 â†’ 1.21.2/3

Source: [Official primer](https://docs.neoforged.net/primer/docs/1.21.2/)
- Entity and item rendering state migrations
- Equipment, data component, recipe, and registry changes
- Client input, GUI, networking, and NeoForge API updates
- Converter passes: `neoforge-26-api`

## 1.21.2/3 â†’ 1.21.4

Source: [Official primer](https://docs.neoforged.net/primer/docs/1.21.4/)
- Client item definitions replace legacy item model overrides
- Item tint, conditional, select, range, composite, and special models
- Particles move through render types
- Resource reload metadata serializers move toward codecs
- Converter passes: `assets`

## 1.21.4 â†’ 1.21.5

Source: [Official primer](https://docs.neoforged.net/primer/docs/1.21.5/)
- Block and item model pipeline rewrite
- Baked models become quad collections/block-state model parts
- Codec-driven reload, timer, and registry context changes
- Game test, JOML interface, tag, and mob-effect changes
- Converter passes: `neoforge-26-api`, `assets`

## 1.21.5 â†’ 1.21.6

Source: [Official primer](https://docs.neoforged.net/primer/docs/1.21.6/)
- GUI prepare/extract/render separation and ordered elements
- Dialog, waypoint, and custom action APIs
- Blaze3D buffers, uniforms, fog, and scissoring changes
- Direct NBT access replaced by generic encode/decode flows
- Tag providers and server-player APIs change
- Converter passes: `mcreator-1.21.x`, `neoforge-26-api`

## 1.21.6 â†’ 1.21.7

Source: [Official primer](https://docs.neoforged.net/primer/docs/1.21.7/)
- Minor vanilla additions, signature changes, and removals

## 1.21.7 â†’ 1.21.8

Source: [Official primer](https://docs.neoforged.net/primer/docs/1.21.8/)
- Minor vanilla additions, signature changes, and removals

## 1.21.8 â†’ 1.21.9

Source: [Official primer](https://docs.neoforged.net/primer/docs/1.21.9/)
- Debug subscriptions and synchronizers
- Level.isClientSide field becomes private; use the method
- ContainerUser replaces Player in container lifecycle APIs
- Profile/name-id, GUI, world, and tag changes
- Converter passes: `neoforge-26-api`, `mcreator-1.21.x`

## 1.21.9 â†’ 1.21.10

Source: [Official primer](https://docs.neoforged.net/primer/docs/1.21.10/)
- Minor vanilla additions, signature changes, and removals

## 1.21.10 â†’ 1.21.11

Source: [Official primer](https://docs.neoforged.net/primer/docs/1.21.11/)
- Permission and permission-set overhaul
- New combat/use data components
- Environment attributes and timelines
- Game rule key/value rewrite
- Text collectors, slot sources, annotations, and tags
- Converter passes: `neoforge-26-api`

## 1.21.11 â†’ 26.1

Source: [Official primer](https://docs.neoforged.net/primer/docs/26.1/)
- Java 25 and deobfuscated vanilla
- Loot codecs and validation overhaul
- Datapack villager trades
- Item instances, stack templates, recipes, and dye components
- World clocks, time markers, and saved-data split
- Rendering materials, models, tints, GUI extraction, fluids, camera, and feature submission
- Converter passes: `neoforge-26-api`, `mcreator-1.21.x`, `assets`

## 26.1 â†’ 26.2

Source: [Official primer](https://docs.neoforged.net/primer/docs/26.2/)
- Vulkan-aware rendering and generalized Blaze3D
- Blend, GPU, vertex-format, bind-group, and render-pass rewrites
- GUI/HUD reorganization and prepared font rendering
- Feature rendering replaces direct MultiBufferSource uploads
- Registry objects split into identifier and object holder classes
- Advancement predicates, object collections, tags, and data components
- Converter passes: `neoforge-26-api`, `assets`
