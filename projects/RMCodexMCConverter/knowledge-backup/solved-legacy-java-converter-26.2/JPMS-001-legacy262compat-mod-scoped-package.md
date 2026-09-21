# JPMS-001 — Legacy262Compat must be mod-scoped

## Symptom

NeoForge / FML fails at scan with:

```text
java.lang.module.ResolutionException: Modules <modA> and <modB>
export package rb.legacy.converter.compat to module jei
```

(or any third module). Two converted jars both contain `rb/legacy/converter/compat/Legacy262Compat.class`.

## Root cause

`Convert-NeoForge262ApiMoves` used to inject FQCNs under the **shared** package `rb.legacy.converter.compat`, and `Invoke-MechanicalJavaRewrites` wrote one `Legacy262Compat.java` there whenever any call site needed it. JPMS forbids two modules exporting the same package.

## Fix (converter)

1. `Get-Legacy262CompatPackage -ModId` → `rb.legacy.converter.compat.<sanitizedModId>`.
2. `Convert-NeoForge262ApiMoves -Text -ModId` inserts / rewrites FQCNs to that package (also rewrites leftover shared FQCNs).
3. `Invoke-MechanicalJavaRewrites -Root -ModId`:
   - deletes `src/main/java/rb/legacy/converter/compat/Legacy262Compat.java` if present
   - writes `.../compat/<modId>/Legacy262Compat.java` **only** when other sources reference the helper
4. Call site: `Invoke-MechanicalJavaRewrites -Root $OutputPath -ModId $meta.mod_id`

## Proven remediation (2026-08-29)

| Mod | Action |
|---|---|
| `mels_deco` | Compat was unused → removed; clean jar has **no** `rb/` entries |
| `nextgen_furniture` | Moved to `rb.legacy.converter.compat.nextgen_furniture`; rebuilt + reinstalled |

Game mods folder: `%APPDATA%\.minecraft\versions\neoforge-26.2.0.72\mods\`

## Agent takeaway

Never ship a shared converter helper package inside mod jars. Any mechanical bridge class must be namespaced by `modId`. If an older jar still has the shared package, rebuild or strip it before loading beside another converted mod.
