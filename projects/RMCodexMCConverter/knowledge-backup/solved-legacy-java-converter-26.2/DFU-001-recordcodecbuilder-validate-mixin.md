# DFU-001 — RecordCodecBuilder / validate accessors / mixin `(T)(Object)this`

## Symptom

Compile fails after Vineflower decompile of NeoForge 1.21.x hand-written mods:

- `no suitable method found for group(...)` with `App<Mu<Object>,…>` / `Kind1.group`
- `Codec<Object>` / `MapCodec<Object>` cannot convert to `Codec<YourRecord>`
- `cannot find symbol` for record **fields** inside `.validate(...)` lambdas (`config.limbs`, `config.rootLimb`)
- Mixin: `XMixin cannot be converted to LivingEntity` / target type (`(LivingEntity)this`)

## Root cause

Vineflower often emits:

1. `RecordCodecBuilder.create(...)` **without** an explicit type witness → inference collapses to `Object`.
2. Record **field** access inside `.validate` lambdas instead of accessors (`limbs` vs `limbs()`).
3. Mixin casts of the form `(Target)this` that javac rejects; need `(Target)(Object)this`.

## Fix (encoded)

Converter pass: `Invoke-DfuCodecRepairPass` in `Convert-Forge1201-ToNeoForge262.ps1`  
Helper: `tools/_apply_dfu_repair.ps1`

| Repair | Before | After |
|---|---|---|
| Type witness | `RecordCodecBuilder.create(` | `RecordCodecBuilder.<T>create(` (same for `mapCodec`) |
| Validate accessors | `config.limbs` / `config.rootLimb` inside balanced `.validate(...)` | `config.limbs()` / `config.rootLimb()` |
| Mixin cast | `(LivingEntity)this` | `(LivingEntity)(Object)this` |
| Noise | CheckerFramework `@NonNull` | strip |

**Scope note:** accessor rewrite must stay inside balanced `.validate(...)` blocks. Blind `builder.field → builder.field()` across the whole file breaks legitimate field uses.

## Proven on

- **CASE-004** `medsystem` NeoForge **1.21.1** → 26.2 (converter **2.0.3+**, green overlay in **2.0.4**)
- Pattern also appears on other hand-written DFU-heavy mods (codecs, health/config records)

## Agent / human checklist

1. Search compile log for `Kind1.group` / `Codec<Object>` / mixin conversion errors.
2. Prefer running/encoding DFU repair — do not hand-fix one file and forget the class of bug.
3. If an **overlay** is applied **after** DFU, the overlay **must already include** these repairs (see **OVY-001**).
4. Verify with `gradlew compileJava` / `build`, not visual inspection alone.

## Related

- `OVY-001-overlay-must-be-green-not-oracle.md`
- `CASE-004-medsystem-1.21.1.md`
