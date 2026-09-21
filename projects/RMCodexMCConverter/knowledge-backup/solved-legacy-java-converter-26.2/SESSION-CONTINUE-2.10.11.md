# Session continue — RB Legacy Java Converter 2.10.11

**Read this first.** Last saved: **2026-09-05**.

## Status

- Destination JDK pin for installer **and agents**: Java **25** for NeoForge 26.2.
- Agents must use `tools/Build-WithDestinationJava.ps1` / `Invoke-GradleBuildWithRequiredJava` — never ambient Java 8 first.
- `Write-GrokRepairPrompt` + `Open-GrokRepairSession` always refresh `GROK_REPAIR_PROMPT.md` with the destination-Java mandate.
- Cat Fighting 26.1.2→26.2 repaired: mixin `(Object) this instanceof` + green `catfighting-1.2.1+mc26.2-neoforge.jar`.

## Related

- `262r/converter/destination-java.md`
- `262r/do-not.md` (ambient Java first)
