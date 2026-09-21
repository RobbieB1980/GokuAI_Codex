# REN-002 — Client package moves (1.21.x → 26.2)

## Symptom

Compile errors: cannot find symbol

- `net.minecraft.client.renderer.block.model.BlockStateModel`
- `net.minecraft.client.renderer.block.model.VariantMutator`
- `net.minecraft.client.renderer.state.CameraRenderState`

## Solution (`Convert-NeoForge262ApiMoves`)

| Old | New |
|---|---|
| `...block.model.BlockStateModel` | `...block.dispatch.BlockStateModel` |
| `...block.model.VariantMutator` | `...block.dispatch.VariantMutator` |
| `...state.CameraRenderState` | `...state.level.CameraRenderState` |

Also: `LevelRenderer.getLightColor` → `LightCoordsUtil.getLightCoords`.

Confirm against `Exact_Version_Sources` / patched Minecraft sources jar when unsure.
