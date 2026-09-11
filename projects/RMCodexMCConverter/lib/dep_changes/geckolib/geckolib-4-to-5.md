# GeckoLib 4 → 5.5.3 (NeoForge 26.2)

| Change ID | Kind | Old | New / action | Executable |
|---|---|---|---|---|
| `gecko-pkg-bernie-to-com` | renamed | `software.bernie.geckolib` | `com.geckolib` | mechanical-java / geckolib pass |
| `gecko-controller-array-add` | signature_changed | `controllers.add(new AnimationController[]{...})` | `controllers.add(new AnimationController<>(...))` | `Invoke-GeckoLib26Pass` |
| `gecko-geo-model-bare-id` | behavioral | geo resource paths with `geo/` + `.json` | bare model IDs under `assets/<mod>/geckolib/models` | assets + geckolib pass |
| `gecko-texture-unknown` | behavioral | `textures/entities/unknown.png` on GeoModel | synched TEXTURE default / entity texture | `Invoke-GeckoLib26Pass` |
| `gecko-procedure-stop` | behavioral | procedurePredicate CONTINUE on empty clip | `PlayState.STOP` when clip empty/undefined | `Invoke-GeckoLib26Pass` |
| `gecko-26.2-pin` | replaced_by | GeckoLib 4 Forge/NeoForge coords | `geckolib-neoforge-26.2:5.5.3` | DependencyCatalog |

## Provenance

- Converter proven: The One Who Watches / Friend (GeckoLib 5 on NeoForge 26.2)
- Upstream source (station): `knowledge/_upstream/geckolib` (`bernie-g/geckolib`)
- Catalog coordinate: `tools/lib/DependencyCatalog.json` → `geckolib`
