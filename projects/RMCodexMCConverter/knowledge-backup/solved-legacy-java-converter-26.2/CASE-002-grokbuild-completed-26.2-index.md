# CASE-002 — GrokBuild completed Java → NeoForge 26.2 conversions

## Canonical location

`F:\rob_projects\Completed\GrokBuild_MF\Completed_Projects\Java\26.2\`

| Subfolder | Contents |
|---|---|
| `Completed_JARS\` | Installable NeoForge 26.2 jars (converted + some third-party) |
| `Gradle_Workspaces\` | Source workspaces that produced those jars |

Station archive (reports + jars, not full huge trees):

`C:\rmblocal_llm\knowledge\Solved_Problems\legacy-java-converter-26.2\cases\grokbuild-completed-26.2\`

## Converter successes (use as reference)

These are **Legacy / jar-pipeline conversions** (or closely related ports) with a produced 26.2 jar.

| Case | Mod ID | Approx source | Workspace | Installable jar |
|---|---|---|---|---|
| Friend | `friend` | Forge **1.20.1** | `Gradle_Workspaces\Friend-26.2` | `friend-1.0.1+mc26.2-neoforge.jar` |
| The One Who Watches | `the_one_who_watches` | Forge **1.20.1** (MCreator) | `Gradle_Workspaces\TheOneWhoWatches-26.2` | `the_one_who_watches-1.4.4+mc26.2-neoforge.1.jar` |
| The Knocker | `the_knocker` | NeoForge **1.21.8** | `Gradle_Workspaces\The_Knocker\the_knocker-1.5.2-neoforge-1.21.8-26.2` | `the_knocker-1.5.2+mc26.2-neoforge.jar` |
| MOAdecor BATH | `moa_bath` | NeoForge/MCreator **1.21.8.A** | `MOAdecor_BATH_1.21.8.A-26.2` | `moa_bath-1.21.8.A+mc26.2-neoforge.jar` |
| MOAdecor ELECTRONICS | `moa_decor_electronics` | **1.21.8.A** | `MOAdecor_ELECTRONICS_1.21.8.A-26.2` | `moa_decor_electronics-1.21.8.+mc26.2-neoforge.jar` |
| MOAdecor GARDEN | `moa_garden` | **1.21.8.A** | `MOAdecor_GARDEN_1.21.8.A-26.2` | `moa_garden-1.21.8.+mc26.2-neoforge.jar` |
| MOAdecor LIGHTS | `moa_lights` | **1.21.8.A** | `MOAdecor_LIGHTS_1.21.8.A-26.2` | `moa_lights-1.21.8.+mc26.2-neoforge.jar` |
| MOAdecor SCIENCE | `moa_science` | **1.21.8.A** | `MOAdecor_SCIENCE_1.21.8.A-26.2` | `moa_science-1.21.8.+mc26.2-neoforge.jar` |
| Hospital Mod | `the_hospital_mod` | Forge **1.12.2** | `Hospital_Mod_1.12.2_(14.23.5.2768)-26.2-10` | `the_hospital_mod-1.0.0+from112-mc26.2-neoforge.jar` |
| BuildPaste | `buildpaste` | NeoForge **26.1.2** | `BuildPaste_NeoForge-26.1.2v2.2.1-26.2` | `buildpaste-2.2.1.jar` |
| ChaosKit | `pchaoskit` | NeoForge/MCreator **26.1.2** | `ChaosKit\ChaosKit-26.2` | `pchaoskit-*.jar` (also listed under Completed_JARS as 26.1.2-named) |
| CreativeSurvival template | `creativesurvival` | template **26.1.2→26.2** | `creativesurvival-template-26.1.2-26.2` | `creativesurvival-1.0.0.jar` |

Related native / lab 26.2 projects (not classic Legacy jar convert, but completed 26.2 jars):

| Jar | Notes |
|---|---|
| `wlf-26.2.0.jar` | `robwolf-26.2` workspace |
| `robmod-26.2.0.jar` | `robmodjava` workspace (very large) |
| `roblab-26.2.0.jar` | Completed_JARS only |

## Primer / route lessons for agents

| Source band | Examples | Agent cue |
|---|---|---|
| Forge 1.20.1 | Friend, TOWW | Full SRG + mechanical + GeckoLib5 + 26.2 API |
| NeoForge 1.21.8 | Knocker, MOAdecor* | `neoforge-1.21.x` + MCreator 1.21.x pass; networking/registerItem lessons in CHANGELOG 1.2.x–1.4.x |
| Forge 1.12.2 | Hospital | Separate **112→26.2** pipeline (`Convert-112ToNeoForge262` / `MIGRATION_112_REPORT`) — not the 1.20.1 converter alone |
| NeoForge 26.1.x | BuildPaste, ChaosKit, CreativeSurvival | Short delta to 26.2; often MDK/template or MCreator updater |

## Third-party jars in Completed_JARS (not Legacy conversions)

Keep available for test instances, but **do not** treat as converter output:

- `sodium-neoforge-0.9.1+mc26.2.jar`
- `lithium-neoforge-0.25.3+mc26.2.jar`
- `iris-neoforge-1.11.2+mc26.2.jar`
- `EuphoriaPatcher-1.9.3-r5.8.1-neoforge.jar`

## How agents should use this

1. Match incoming mod family (horror entity / MCreator decor / 1.12 world / 26.1 bump).
2. Open the matching workspace reports under `cases/grokbuild-completed-26.2/reports/<id>/`.
3. Compare failing patterns to that successful output (registry, networking, GeckoLib, GUI extract).
4. Prefer fixing the **converter rule** so the next run reproduces these jars, rather than hand-copying project trees.

## Also see

- [CASE-001](CASE-001-nextgen-furniture-1.21.1-success.md) — Nextgen Furniture 1.21.1 (newer exact-primer + overlay path)
- Station tools: `C:\rmblocal_llm\projects\RB-Legacy-Java-Converter\tools`
