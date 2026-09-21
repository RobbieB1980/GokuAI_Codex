# Shard — BlockEntityRenderer two type args + submit

**ID:** `mc-262r-ber-render-state`  
**Proven:** Easy Mob Farm `MobFarmBlockEntityRenderer`

## Detect

```java
implements BlockEntityRenderer<T>  // one type arg
public void render(T be, float pt, PoseStack, SubmitNodeCollector, int light, int overlay)
```

## Target (26.2 client.jar)

```java
implements BlockEntityRenderer<T, S extends BlockEntityRenderState>
S createRenderState();
void extractRenderState(T, S, float, Vec3, ModelFeatureRenderer.CrumblingOverlay);
void submit(S, PoseStack, SubmitNodeCollector, CameraRenderState);
```

Custom state subclass holds entity / farm facing for submit. Use `BlockEntityRenderState.extractBase(...)`.

Entity preview inside BER: `EntityRenderDispatcher.submit(state, camera, x, y, z, pose, buffer)` — old `renderer.render(...)` is gone.
