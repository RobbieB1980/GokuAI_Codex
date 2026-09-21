# Converter — soft-dep integration exclude

**Pass:** `Invoke-OptionalIntegrationExcludePass`  
**IDs:** `mc-262r-soft-dep-exclude`, `mc-262r-soft-dep-keep-when-jar`  
**Related:** `INT-001-soft-dep-integration-exclude.md`

## Rule

Strip integration sources that hard-import missing companion APIs **only when** no matching 26.2 jar exists under `libs/`.

| libs/ has | Keep sources under |
|---|---|
| `*jei*` | `compat/jei/**`, `integration/jei/**` |
| `*carryon*` | `integration/carryon/**` |
| `*appleskin*` | `integration/appleskin/**` |
| `*sable*` | `integration/sable/**` |

Always safe to exclude: `**/gametest/**` (harness not on leaf classpath).

**Converter rule (2.10.9+ repair):** `Invoke-OptionalIntegrationExcludePass` must:
1. **Delete** `**/gametest/**/*.java` under `src/main/java` (exclude alone was not enough on some MDG runs), and
2. Write `exclude '**/gametest/**'` into `build.gradle`,
**even when no soft-dep files were deleted**. Previously the exclude was gated on `$touched -gt 0`, so a JEI-present Easy Mob Farm re-run left GameTest sources on the compile classpath (`GameTest` / `GameTestHolder` / `PrefixGameTestTemplate` missing).

CASE-006 also ships `lib/overlays/easy-mob-farm/1.21.4/DELETE.txt` as a belt-and-suspenders overlay delete list.

## Path markers

- `integration/{carryon,sable,jei,appleskin}/`
- `compat/jei/` (Easy Mob Farm shape)
- `gametest/` (always exclude Java sources)

## Proven

Easy Mob Farm: after dual-pull JEI 26.2 into `libs/`, remove `exclude '**/compat/jei/**'` and compile against the jar. Always keep `exclude '**/gametest/**'`.
