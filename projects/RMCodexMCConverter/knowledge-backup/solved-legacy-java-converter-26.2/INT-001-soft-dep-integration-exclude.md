# INT-001 — Soft-dep integration exclude (Carry On / Sable / JEI / …)

## Symptom

Converted leaf mod fails compile because optional companion mods are referenced:

- `import tschipp.carryon...`
- `import dev.leo.sableplayerragdoll...`
- or Integration classes under `.../integration/carryon/` / `.../integration/sable/` that assume those mods exist

Even when EventListener files are deleted, **`CarryOnIntegration.java` / `SableIntegration.java`** may remain if they only use `ModList.isLoaded(...)` and never hard-import the soft package.

## Fix (encoded)

Pass: `Invoke-OptionalIntegrationExcludePass`

1. Delete Java under integration trees that either:
   - hard-import known soft packages (`tschipp.carryon`, `dev.leo.sableplayerragdoll`, `mezz.jei`, `squeek.appleskin`), **or**
   - live under path markers `integration/carryon|sable|jei|appleskin`
2. Record deleted relative paths in `OPTIONAL_INTEGRATIONS_EXCLUDED.txt`
3. Add Gradle `sourceSets.main.java { exclude '**/integration/carryon/**' ... }` as belt-and-suspenders

Overlay `DELETE.txt` (OVY-001) should still list Integration files for solved mods so a full overlay apply removes them even if the soft-dep pass order changes.

## Agent takeaway

Do not require users to install Carry On / Sable just to compile a medical/furniture leaf mod. Soft integrations are optional at runtime; missing compile classpath must not block the installable JAR.

## Related

- `CASE-004-medsystem-1.21.1.md`
- `OVY-001-overlay-must-be-green-not-oracle.md`
